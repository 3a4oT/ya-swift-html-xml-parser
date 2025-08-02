#ifndef LIBXML_TRAMPOLINES_H
#define LIBXML_TRAMPOLINES_H

#include <libxml/parser.h>

#ifdef __cplusplus
extern "C" {
#endif

// Forward declarations of Swift bridge functions (implemented with @_cdecl in Swift)
void swift_xml_startDocument(void *ctx);
void swift_xml_endDocument(void *ctx);
void swift_xml_startElement(void *ctx, const xmlChar *name, const xmlChar **attrs);
void swift_xml_endElement(void *ctx, const xmlChar *name);
void swift_xml_characters(void *ctx, const xmlChar *ch, int len);
void swift_xml_comment(void *ctx, const xmlChar *value);
void swift_xml_cdata(void *ctx, const xmlChar *value, int len);
void swift_xml_processingInstruction(void *ctx, const xmlChar *target, const xmlChar *data);
void swift_xml_error(void *ctx, const char *msg);

// Fills the provided xmlSAXHandler structure with C trampolines that forward
// into the Swift @_cdecl functions above.
void libxml_install_swift_trampolines(xmlSAXHandler *handler);

#ifdef __cplusplus
}
#endif

#endif /* LIBXML_TRAMPOLINES_H */
