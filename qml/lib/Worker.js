Qt.include("codebird.js")
Qt.include("common.js")


function showError(status, statusText) {
    console.log(status)
    console.log(statusText)
}



function parseDM(dmJson, isReceiveDM) {
    var dm = {
        id: dmJson.id_str,
        richText: __toRichText(dmJson.text, dmJson.entities),
        name: (isReceiveDM ? dmJson.sender.name : dmJson.recipient.name),
        highlights: __toHighlights(dmJson.text, dmJson.entities),
        screenName: (isReceiveDM ? dmJson.sender_screen_name : dmJson.recipient_screen_name),
        profileImageUrl: (isReceiveDM ? dmJson.sender.profile_image_url : dmJson.recipient.profile_image_url),
        createdAt: dmJson.created_at,
        isReceiveDM: isReceiveDM
    }
    return dm;
}



WorkerScript.onMessage = function(msg) {
    var cb = new Fcodebird;
    cb.setUseProxy(false);
    if (msg.conf.OAUTH_CONSUMER_KEY && msg.conf.OAUTH_CONSUMER_SECRET ){
        cb.setConsumerKey(msg.conf.OAUTH_CONSUMER_KEY, msg.conf.OAUTH_CONSUMER_SECRET);
    }


    if (msg.conf.OAUTH_TOKEN && msg.conf.OAUTH_TOKEN_SECRET){
        cb.setToken(msg.conf.OAUTH_TOKEN, msg.conf.OAUTH_TOKEN_SECRET);
    }

    var sinceId;
    var maxId;



    if (msg.action === 'statuses_homeTimeline' || msg.action === 'statuses_mentionsTimeline') {
        var params = {"count":5}
        sinceId = false;
        maxId = false;
        if (msg.model.count) {
            if (msg.mode === "append") {
                params['maxId'] = msg.model.get(msg.model.count-1).id
            }
            if (msg.mode === "prepend") {
                params['sinceId'] = msg.model.get(0).id
            }
        }
        console.log(JSON.stringify(params))
        cb.__call(
            msg.action,
            params,
            function (reply, rate, err) {
                //msg.model.clear()
                for (var i=0; i < reply.length; i++) {
                    var tweet = parseTweet(reply[i]);
                    if (msg.model.count) {
                        if (msg.mode === "append" && i > 0) {
                            msg.model.append(tweet)
                        }
                        if (msg.mode === "prepend") {
                            msg.model.insert(0, tweet)
                        }
                    } else {
                        msg.model.append(tweet)
                    }
                }
                msg.model.sync();
                console.log(msg.model.count);
                // console.log(JSON.stringify(err));
            }
        );
    }



    if (msg.action === 'getDirectMsg') {
        console.log('getDirectMsg '+JSON.stringify(msg))
        sinceId = false;
        maxId = false;
        if (msg.model.count) {
            if (msg.mode === "append") {
                maxId = msg.model.get(msg.model.count-1).id
            }
            if (msg.mode === "prepend") {
                sinceId = msg.model.get(0).id
            }
        }

        getDirectMsg(sinceId, maxId, function(data) {
            //msg.model.clear();
            for (var i=0; i < data.length; i++) {
                console.log(JSON.stringify(data[i]))
                var tweet = parseDM(data[i], true);
                if (msg.model.count) {
                    if (msg.mode === "append" && i > 0) {
                        console.log('append')
                        msg.model.append(tweet)
                    }
                    if (msg.mode === "prepend") {
                        console.log('prepend')
                        msg.model.insert(0, tweet)
                    }
                } else {
                    msg.model.append(tweet)
                }
            }
            msg.model.sync();
        }, showError)
    }

    if (msg.action === 'postTweet') {
        console.log('postTweet '+JSON.stringify(msg))

    }

}
//WorkerScript.sendMessage({ 'reply': 'Mouse is at ' + message.x + ',' + message.y })

