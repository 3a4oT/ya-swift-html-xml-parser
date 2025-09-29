import CLibXML2
import LibXMLTrampolines

@inline(__always)
private func cString(_ ptr: UnsafePointer<xmlChar>) -> String {
    String(cString: UnsafePointer<CChar>(OpaquePointer(ptr)))
}

// MARK: - Bridging C trampolines to Swift events

@_cdecl("swift_xml_startDocument")
func swift_xml_startDocument(_ ctx: UnsafeMutableRawPointer?) {
    guard let ctx else { return }
    let parser = Unmanaged<StreamParser>.fromOpaque(ctx).takeUnretainedValue()
    parser.deliver(.startDocument)
}

@_cdecl("swift_xml_endDocument")
func swift_xml_endDocument(_ ctx: UnsafeMutableRawPointer?) {
    guard let ctx else { return }
    let parser = Unmanaged<StreamParser>.fromOpaque(ctx).takeUnretainedValue()
    parser.deliver(.endDocument)
}

@_cdecl("swift_xml_startElement")
func swift_xml_startElement(_ ctx: UnsafeMutableRawPointer?, _ name: UnsafePointer<xmlChar>?, _ attrs: UnsafePointer<UnsafePointer<xmlChar>?>?) {
    guard let ctx, let name else { return }
    let parser = Unmanaged<StreamParser>.fromOpaque(ctx).takeUnretainedValue()
    let elementName = cString(name)
    var attributes: [(String, String)] = []
    if let attrs {
        var i = 0
        while let attrNamePtr = attrs[i] {
            let valuePtr = attrs[i + 1]
            let attrName = cString(attrNamePtr)
            let value = valuePtr.map { cString($0) } ?? ""
            attributes.append((attrName, value))
            i += 2
        }
    }
    parser.deliver(.startElement(name: elementName, attributes: attributes))
}

@_cdecl("swift_xml_endElement")
func swift_xml_endElement(_ ctx: UnsafeMutableRawPointer?, _ name: UnsafePointer<xmlChar>?) {
    guard let ctx, let name else { return }
    let parser = Unmanaged<StreamParser>.fromOpaque(ctx).takeUnretainedValue()
    parser.deliver(.endElement(name: cString(name)))
}

@_cdecl("swift_xml_characters")
func swift_xml_characters(_ ctx: UnsafeMutableRawPointer?, _ ch: UnsafePointer<xmlChar>?, _ len: Int32) {
    guard let ctx, let ch else { return }
    let parser = Unmanaged<StreamParser>.fromOpaque(ctx).takeUnretainedValue()
    let str = String(decoding: UnsafeBufferPointer(start: ch, count: Int(len)), as: UTF8.self)
    parser.deliver(.characters(str))
}

@_cdecl("swift_xml_comment")
func swift_xml_comment(_ ctx: UnsafeMutableRawPointer?, _ value: UnsafePointer<xmlChar>?) {
    guard let ctx, let value else { return }
    let parser = Unmanaged<StreamParser>.fromOpaque(ctx).takeUnretainedValue()
    parser.deliver(.comment(cString(value)))
}

@_cdecl("swift_xml_cdata")
func swift_xml_cdata(_ ctx: UnsafeMutableRawPointer?, _ value: UnsafePointer<xmlChar>?, _ len: Int32) {
    guard let ctx, let value else { return }
    let parser = Unmanaged<StreamParser>.fromOpaque(ctx).takeUnretainedValue()
    let cdata = String(decoding: UnsafeBufferPointer(start: value, count: Int(len)), as: UTF8.self)
    parser.deliver(.cdata(cdata))
}

@_cdecl("swift_xml_processingInstruction")
func swift_xml_processingInstruction(_ ctx: UnsafeMutableRawPointer?, _ target: UnsafePointer<xmlChar>?, _ data: UnsafePointer<xmlChar>?) {
    guard let ctx, let target else { return }
    let parser = Unmanaged<StreamParser>.fromOpaque(ctx).takeUnretainedValue()
    let targetString = cString(target)
    let dataString = data.map { cString($0) }
    parser.deliver(.processingInstruction(target: targetString, data: dataString))
}

@_cdecl("swift_xml_error")
func swift_xml_error(_ ctx: UnsafeMutableRawPointer?, _ msg: UnsafePointer<CChar>?) {
    guard let ctx, let msg else { return }
    let parser = Unmanaged<StreamParser>.fromOpaque(ctx).takeUnretainedValue()
    let message = String(cString: msg)
    parser.deliver(.error(message.trimmingWhitespace()))
}
