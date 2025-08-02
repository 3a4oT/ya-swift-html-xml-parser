#include "LibXMLTrampolines.h"
#include <string.h>

// ---- C trampolines that simply forward to Swift global functions ----

static void _startDocument(void *ctx) {
    swift_xml_startDocument(ctx);
}

static void _endDocument(void *ctx) {
    swift_xml_endDocument(ctx);
}

static void _startElement(void *ctx, const xmlChar *name, const xmlChar **attrs) {
    swift_xml_startElement(ctx, name, attrs);
}

static void _endElement(void *ctx, const xmlChar *name) {
    swift_xml_endElement(ctx, name);
}

static void _characters(void *ctx, const xmlChar *ch, int len) {
    swift_xml_characters(ctx, ch, len);
}

static void _comment(void *ctx, const xmlChar *value) {
    swift_xml_comment(ctx, value);
}

static void _cdata(void *ctx, const xmlChar *value, int len) {
    swift_xml_cdata(ctx, value, len);
}

static void _processingInstruction(void *ctx, const xmlChar *target, const xmlChar *data) {
    swift_xml_processingInstruction(ctx, target, data);
}

static void _error(void *ctx, const char *msg, ...) {
    // libxml2 sends printf-style varargs; we just forward the raw message string.
    swift_xml_error(ctx, msg);
}

// Public function: fill handler with pointers to the above trampolines
void libxml_install_swift_trampolines(xmlSAXHandler *handler) {
    if (!handler) return;
    memset(handler, 0, sizeof(xmlSAXHandler));

    handler->startDocument        = _startDocument;
    handler->endDocument          = _endDocument;
    handler->startElement         = _startElement;
    handler->endElement           = _endElement;
    handler->characters           = _characters;
    handler->comment              = _comment;
    handler->cdataBlock           = _cdata;
    handler->processingInstruction= _processingInstruction;
    handler->error                = (errorSAXFunc) _error;
}
