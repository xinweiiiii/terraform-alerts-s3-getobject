const https = require('https');
const zlib = require('zlib');

exports.handler = async (event) => {
    const data = event.awslogs.data
    const compressedPayload = Buffer.from(data, 'base64')
    const jsonPayload = zlib.gunzipSync(compressedPayload).toString('utf8')

    const listDataEvents = JSON.parse(jsonPayload).logEvents

    for (let dataEvent of listDataEvents) {
        const username = JSON.parse(dataEvent.message).userIdentity.principalId
        const objectKey = JSON.parse(dataEvent.message).requestParameters.key

        if (username != '' && objectKey != '') {
            const notificationData = {
                blocks: [
                    {
                        type: 'section',
                        text: {
                            text: `*S3 Object Extracted* Date: *${getDateTime()}`,
                            type: 'mrkdwn',
                        },
                    },
                ],
            };

            const res = await post(process.env.webhook_url, notificationData)
        }
    }

    async function post(url, notificationData) {
        const dataString = JSON.stringify(notificationData)

        const options = {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': dataString.length,
            },
            timeout: 1000, // in ms
        }

        return new Promise((resolve, reject) => {
            const req = https.request(url, options, (res) => {
                if (res.statusCode < 200 || res.statusCode > 299) {
                    return reject(new Error(`HTTP status code ${res.statusCode}`))
                }

                const body = []
                res.on('data', (chunk) => body.push(chunk))
                res.on('end', () => {
                    const resString = Buffer.concat(body).toString()
                    resolve(resString)
                })
            })

            req.on('error', (err) => {
                reject(err)
            })

            req.on('timeout', () => {
                req.destroy()
                reject(new Error('Request time out'))
            })

            req.write(dataString)
            req.end()
        })
    }

    function padTo2Digits(num) {
        return num.toString().padStart(2, '0');
    }

    function formatDate(date) {
        return [
            padTo2Digits(date.getDate()),
            padTo2Digits(date.getMonth() + 1),
            date.getFullYear(),
        ].join('/');
    }

    function getDateTime() {
        const today = new Date();
        const date = formatDate(today)
        const time = padTo2Digits(today.getHours()) + ":" + padTo2Digits(today.getMinutes()) + ":" + padTo2Digits(today.getSeconds());
        return date+' '+time;
    }
};
