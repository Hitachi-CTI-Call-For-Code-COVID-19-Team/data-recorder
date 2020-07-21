function main(params) {
        var result = params.messages[0].value
        console.log(params.messages)
        result["format"] = "json"
        var dt = new Date()
        result.timestamp = dt.toISOString()
        return {
                    dbname: "iotp_o9ypqz_default_" + getDateString(dt),
                    doc: result
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
