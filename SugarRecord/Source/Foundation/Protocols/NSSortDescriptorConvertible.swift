import Foundation

public protocol NSSortDescriptorConvertible {
    
    init(sortDescriptors: [NSSortDescriptor])
    init(sortDescriptor: NSSortDescriptor)
    var sortDescriptors: [NSSortDescriptor]? { get }

}
