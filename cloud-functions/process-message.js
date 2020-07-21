 function main(params) {
    var dt
    var docs = params.messages.map(message => {
        doc = message.value
        doc["format"] = "json"
        dt = new Date()
        doc.timestamp = dt.toISOString()
        return doc
    })
    return {
        dbname: "z_iotp_o9ypqz_default_" + getDateString(dt),
        docs: { docs: docs}
    }
}

function getDateString(dt) {
    var YYYY = dt.getUTCFullYear()
    var month = dt.getUTCMonth() + 1
    var MM = month < 10 ? '0' + month : month
    var day = dt.getUTCDate()
    var DD = day < 10 ? '0' + day : day
    return YYYY + "-" + MM + "-" + DD
}
