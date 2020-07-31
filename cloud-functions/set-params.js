function main(params) {
        return {
                    dbname: "z_iotp_o9ypqz_default_" + getDateString(new Date()),
                };
}

function getDateString(dt) {
        dt.setDate( dt.getDate() + 1 ) // next day
        
        var YYYY = dt.getUTCFullYear()
        var month = dt.getUTCMonth() + 1
        var MM = month < 10 ? '0' + month : month
        var day = dt.getUTCDate()
        var DD = day < 10 ? '0' + day : day
        return YYYY + "-" + MM + "-" + DD
}
