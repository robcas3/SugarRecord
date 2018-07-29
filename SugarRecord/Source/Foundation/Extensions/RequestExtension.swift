import Foundation


// MARK: Request extension (NSPredicateConvertible)

extension FetchRequest: NSPredicateConvertible {
    
    public init(predicate: NSPredicate) {
        self = FetchRequest(nil, predicate: predicate)
    }
}


// MARK: Request extension (NSSortDescriptorConvertible)

extension FetchRequest: NSSortDescriptorConvertible {
    
    public init(sortDescriptor: NSSortDescriptor) {
        self = FetchRequest(sortDescriptors: [sortDescriptor])
    }

    public init(sortDescriptors: [NSSortDescriptor]) {
        self = FetchRequest(nil, sortDescriptors: sortDescriptors)
    }
}
