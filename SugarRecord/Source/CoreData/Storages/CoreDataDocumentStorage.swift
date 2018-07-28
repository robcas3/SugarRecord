//
//  CoreDataDocumentStorage.swift
//  iOSCoreData
//
//  Created by Roberto Casula on 21/07/18.
//  Copyright © 2018 in.caramba.SugarRecord. All rights reserved.
//

import AppKit
import CoreData

public class CoreDataDocumentStorage: Storage {
    
    // MARK: - Attributes
    internal var objectModel: NSManagedObjectModel
    internal var persistentStoreCoordinator: NSPersistentStoreCoordinator
    internal var rootSavingContext: NSManagedObjectContext
    
    
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
                returnedObject = try operation(context, { [weak self] () -> Void in
                    guard let s = self else { return }
                    do {
                        try context.save()
                    } catch {
                        _error = error
                    }
                    guard !s.persistentStoreCoordinator.persistentStores.isEmpty
                        else { return }
                    s.rootSavingContext.performAndWait({
                        if s.rootSavingContext.hasChanges {
                            do {
//                                try s.rootSavingContext.save()
                            } catch {
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
            operation(context, { [weak self] () -> Void in
                guard let s = self else { return }
                do {
                    try context.save()
                } catch {
                    _error = error
                }
                guard !s.persistentStoreCoordinator.persistentStores.isEmpty
                    else { return }
                s.rootSavingContext.perform {
                    if s.rootSavingContext.hasChanges {
                        do {
//                            try s.rootSavingContext.save()
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
    
    public func removeStore() throws {}
    
    public init(model: NSManagedObjectModel,
                context: NSManagedObjectContext) {
        self.objectModel = model
        self.persistentStoreCoordinator = context.persistentStoreCoordinator!
        self.rootSavingContext = context
        self.mainContext = cdContext(withParent: .context(self.rootSavingContext), concurrencyType: .mainQueueConcurrencyType, inMemory: false)
    }
    
    
    // MARK: - Public
    
    @available(OSX 10.12, iOS 9, watchOS 2, tvOS 9, *)
    public func observable<T: NSManagedObject>(request: FetchRequest<T>) -> RequestObservable<T> {
        return CoreDataObservable(request: request, context: self.mainContext as! NSManagedObjectContext)
    }
    
}
