//
//  CoreDataDocumentStorage.swift
//  iOSCoreData
//
//  Created by Roberto Casula on 21/07/18.
//  Copyright © 2018 in.caramba.SugarRecord. All rights reserved.
//

import Foundation
import CoreData

public class CoreDataDocumentStorage: Storage {
    
    // MARK: - Attributes
    
    internal var objectModel: NSManagedObjectModel! = nil
    internal var persistentStore: NSPersistentStore! = nil
    internal var persistentStoreCoordinator: NSPersistentStoreCoordinator! = nil
    internal var rootSavingContext: NSManagedObjectContext! = nil
    
    
    // MARK: - Storage conformance
    
    public var description: String {
        get {
            return "CoreDataDocumentStorage"
        }
    }
    
    public var type: StorageType = .coreData
    public var mainContext: Context!
    private var _saveContext: Context!
    public var saveContext: Context! {
        if let context = self._saveContext {
            return context
        }
        let _context = cdContext(withParent: .context(self.rootSavingContext), concurrencyType: .privateQueueConcurrencyType, inMemory: false)
        _context.observe(inMainThread: true) { [weak self] (notification) -> Void in
            (self?.mainContext as? NSManagedObjectContext)?.mergeChanges(fromContextDidSave: notification as Notification)
        }
        self._saveContext = _context
        return _context
    }
    public var memoryContext: Context! {
        let _context =  cdContext(withParent: .context(self.rootSavingContext), concurrencyType: .privateQueueConcurrencyType, inMemory: true)
        return _context
    }
    
    
    public func operation<T>(_ operation: @escaping (_ context: Context, _ save: @escaping () -> Void) throws -> T) throws -> T {
        let context: NSManagedObjectContext = self.saveContext as! NSManagedObjectContext
        var _error: Error!
        
        var returnedObject: T!
        context.performAndWait {
            do {
                returnedObject = try operation(context, { () -> Void in
                    do {
                        try context.save()
                    }
                    catch {
                        _error = error
                    }
                    self.rootSavingContext.performAndWait({
                        if self.rootSavingContext.hasChanges {
                            do {
                                try self.rootSavingContext.save()
                            }
                            catch {
                                _error = error
                            }
                        }
                    })
                })
            } catch {
                _error = error
            }
        }
        if let error = _error {
            throw error
        }
        
        return returnedObject
    }
    
    public func backgroundOperation(_ operation: @escaping (_ context: Context, _ save: @escaping () -> Void) -> (), completion: @escaping (Error?) -> ()) {
        let context: NSManagedObjectContext = self.saveContext as! NSManagedObjectContext
        var _error: Error!
        context.perform {
            operation(context, { () -> Void in
                do {
                    try context.save()
                }
                catch {
                    _error = error
                }
                self.rootSavingContext.perform {
                    if self.rootSavingContext.hasChanges {
                        do {
                            try self.rootSavingContext.save()
                        }
                        catch {
                            _error = error
                        }
                    }
                    completion(_error)
                }
            })
        }
    }
    
    public func removeStore() throws {
//        try FileManager.default.removeItem(at: store.path() as URL)
//        _ = try? FileManager.default.removeItem(atPath: "\(store.path().absoluteString)-shm")
//        _ = try? FileManager.default.removeItem(atPath: "\(store.path().absoluteString)-wal")
//
    }
    
    
    // MARK: - Init
    
//    public convenience init(store: CoreDataStore, model: CoreDataObjectModel, migrate: Bool = true) throws {
//        try self.init(store: store, model: model, migrate: migrate, versionController: VersionController())
//    }
//
//    internal init(store: CoreDataStore, model: CoreDataObjectModel, migrate: Bool = true, versionController: VersionController) throws {
//        self.store   = store
//        self.objectModel = model.model()!
//        self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel)
//        self.persistentStore = try cdInitializeStore(store: store, storeCoordinator: persistentStoreCoordinator, migrate: migrate)
//        self.rootSavingContext = cdContext(withParent: .coordinator(self.persistentStoreCoordinator), concurrencyType: .privateQueueConcurrencyType, inMemory: false)
//        self.mainContext = cdContext(withParent: .context(self.rootSavingContext), concurrencyType: .mainQueueConcurrencyType, inMemory: false)
//        #if DEBUG
//        versionController.check()
//        #endif
//    }
    
    public init (context: NSManagedObjectContext,
                 model: NSManagedObjectModel) {
        self.objectModel = model
        self.mainContext = context
        self.rootSavingContext = context
        self.persistentStoreCoordinator = context.persistentStoreCoordinator
    }
    
    
    // MARK: - Public
    
    @available(OSX 10.12, iOS 9, watchOS 2, tvOS 9, *)
    public func observable<T: NSManagedObject>(request: FetchRequest<T>) -> RequestObservable<T> {
        return CoreDataObservable(request: request, context: self.mainContext as! NSManagedObjectContext)
    }
    
}
