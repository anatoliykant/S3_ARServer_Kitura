import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudEnvironment
import KituraContracts
import Health
import KituraStencil

public let projectPath = ConfigurationManager.BasePath.project.path
public let health = Health()

public class App {
    let router = Router()
    let cloudEnv = CloudEnv()

    var rootDirectoryPath: String {
		let fileManager = FileManager()
		let currentPath = fileManager.currentDirectoryPath
		return currentPath
	}
	
	var rootDirectory: URL {
		URL(fileURLWithPath: rootDirectoryPath)
	}
	var publicDirectory: URL {
		rootDirectory.appendingPathComponent("public")
	}
	
	var uploadsDirectory: URL {
		publicDirectory.appendingPathComponent("uploads")// FIXME: add prefix public/
	}
	
	var originalsDirectory: URL {
		uploadsDirectory.appendingPathComponent("originals")
	}
	
	var thumbsDirectory: URL {
		uploadsDirectory.appendingPathComponent("thumbs")
	}

    public init() throws {
        // Configure logging
        initializeLogging()
        // Run the metrics initializer
        initializeMetrics(router: router)
    }

    func postInit() throws {
        //Set Stencil as template engine
		
		router.setDefault(templateEngine: StencilTemplateEngine())
		
		// Endpoints
		
		initializeHealthRoutes(app: self)
		
		// routers
		
		router.all("/pikachu",
				   middleware: StaticFileServer(path: "\(rootDirectoryPath)/public/Pikachu"))
		
		router.all("/originals",
				   middleware: StaticFileServer(path: originalsDirectory.path))
		
		router.get("/public*") { [weak self] request, response, next in
			guard let self = self else { return }
			defer { next() }
			
			let fileManager = FileManager()
			
			guard let allObjects = try? fileManager.contentsOfDirectory(
				at: self.originalsDirectory,
				includingPropertiesForKeys: nil,
				options: .skipsHiddenFiles) else {
				return
			}
			
			let files = allObjects.filter { $0.lastPathComponent.contains(".") }.compactMap{ $0.lastPathComponent }
			
			print(#line, #function, "files: ", files)
			
			try response.render("list", context: ["files": files])
		}
		
		router.all("/upload", middleware: BodyParser())
		
		router.post("/upload") { [weak self] request, response, next in
			
			guard let self = self else { return }
			
			func createThumbnail(_ url: URL) -> Data? {
				return nil //TODO: add implementation
			}
				
			defer { next() }
			
			Log.info("request")
			dump(request.body)
			
			guard 
				let values = request.body,
				case .multipart(let parts) = values else { return }
			
			print(#file, #line)
			
			let acceptableType = [
				"image/png", 
				"image/jpg",
				"image/jpeg",
				"model/vnd.pixar.usd",
				"model.usd"
			]
			
			for part in parts {
				
				Log.info("part: \(part)")
				
				guard
					acceptableType.contains(part.type),
					case .raw(let data) = part.body else { continue }
				
				let cleanedFilename = part.filename.replacingOccurrences(of: " ", with: "_")
				let newURL = self.originalsDirectory.appendingPathComponent(cleanedFilename)
				let thumbsURL = self.thumbsDirectory.appendingPathComponent(cleanedFilename)
				
				do {
					try self.write(image: data, with: newURL)
					
					Log.info("newURL: \(newURL)")
					
					if let image = createThumbnail(newURL) {
						do {
							try self.write(image: image, with: thumbsURL)
							
							Log.info("newURL: \(thumbsURL)")
						} catch let error {
							Log.error("ERROR writing thubmnail file \(newURL): \(error.localizedDescription)")
						}
					}
				} catch let error {
					Log.error("ERROR writing original file \(newURL): \(error.localizedDescription)")
				}
			}
			
			Log.info("redirect")
			
			do {
				try response.redirect("/public")
			} catch let error {
				Log.error("ERROR render: \(error.localizedDescription)")
			}
		}
    }

    public func run() throws {
        try postInit()
        Kitura.addHTTPServer(onPort: 9000 /*cloudEnv.port*/, with: router)
        Kitura.run()
    }
	
	// MARK: - Private methods
	
	private func write(image: Data, with url: URL) throws {
		//do {
			try image.write(to: url)
//		} catch let error {
//			Log.error("ERROR writing file \(url): \(error.localizedDescription)")
//		}
	}
}
