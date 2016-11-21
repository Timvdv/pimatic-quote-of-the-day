module.exports = {
  title: "Quote of the day plugin"
  QuoteDevice: {
    title: "Quote of the day"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      quote:
        description: "the quote of the day"
        type: "string"
  }
}
