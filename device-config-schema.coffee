module.exports = {
  title: "Quote of the day plugin"
  QuoteDevice:
    title: "Quote of the day"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      id:
        description: "the id"
        type: "number"
      name:
        description: "name"
        type: "string"
      quote:
        description: "the quote of the day"
        type: "string"
        default: ""
}