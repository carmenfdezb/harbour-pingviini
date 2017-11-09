import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import "../../lib/Logic.js" as Logic

BackgroundItem {
    signal send (string notice)
    id: delegate

    signal navigateTo(string link)
    property variant tweet;
    property bool miniDisplayMode: false;
    width: parent.width
    height: 2*Theme.paddingLarge + (lblText.height + lblName.height > avatar.height ? lblText.height + lblName.height : avatar.height)+ media.height + (tweet.is_quote_status ? loader.height : 0) + mnu.height
    Image {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: Theme.paddingLarge
        anchors.leftMargin: Theme.horizontalPageMargin
        id: avatar
        asynchronous: true
        width: miniDisplayMode ? Theme.iconSizeSmall : Theme.iconSizeMedium
        height: width
        smooth: true
        source: tweet.profileImageUrl
        opacity: status === Image.Ready ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator {} }
        onStatusChanged: {
            if (status === Image.Error)
                source = "image://theme/icon-m-person?" + (pressed
                                                           ? Theme.highlightColor
                                                           : Theme.primaryColor)
        }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                pageStack.push(Qt.resolvedUrl("../Profile.qml"), {
                                   "name": tweet.name,
                                   "username": tweet.screenName,
                                   "profileImage": tweet.profileImageUrl
                               })
            }

        }

    }


    Label {
        id: lblName
        anchors {
            top: avatar.top
            left: avatar.right
            leftMargin: Theme.paddingMedium
        }
        text: tweet.hasOwnProperty("name") ? tweet.name: false
        font.weight: Font.Bold
        font.pixelSize: miniDisplayMode ? Theme.fontSizeExtraSmall : Theme.fontSizeSmall
        color: (pressed ? Theme.highlightColor : Theme.primaryColor)
    }
    Image {
        id: iconVerified
        anchors {
            left: lblName.right
            verticalCenter: lblName.verticalCenter
            leftMargin: tweet.isVerified ? Theme.paddingMedium : 0
        }
        width: tweet.hasOwnProperty("isVerified") && tweet.isVerified ? Theme.iconSizeExtraSmall*0.8 : 0
        opacity: 0.8
        height: width
        source: "../../verified.svg"
        ColorOverlay {
            anchors.fill: parent
            source: iconVerified
            color: (pressed ? Theme.secondaryHighlightColor : Theme.secondaryColor)
        }
    }

    Label {
        id: lblScreenName
        anchors {
            left: iconVerified.right
            right: lblDate.left
            baseline: lblName.baseline
            leftMargin: Theme.paddingMedium
        }
        truncationMode: TruncationMode.Fade
        text: '@'+tweet.screenName
        font.pixelSize: Theme.fontSizeExtraSmall
        color: (pressed ? Theme.secondaryHighlightColor : Theme.secondaryColor)
    }

    Label {
        id: lblDate
        color: (pressed ? Theme.highlightColor : Theme.primaryColor)
        text: Format.formatDate(tweet.created_at, new Date() - tweet.created_at < 60*60*1000 ? Formatter.DurationElapsedShort : Formatter.TimeValueTwentyFourHours)
        font.pixelSize: Theme.fontSizeExtraSmall
        horizontalAlignment: Text.AlignRight
        anchors {
            right: parent.right
            baseline: lblName.baseline
            rightMargin: Theme.horizontalPageMargin
        }
    }
    Label {
        id: lblText
        anchors {
            left: miniDisplayMode ? avatar.left : lblName.left
            right: parent.right
            top: miniDisplayMode ? avatar.bottom : lblName.bottom
            topMargin: Theme.paddingSmall
            rightMargin: Theme.paddingLarge
        }
        height: richText.length ? paintedHeight : 0
        onLinkActivated: {
            console.log(link)
            if (link[0] === "@") {
                pageStack.push(Qt.resolvedUrl("../Profile.qml"), {
                                   "name": "",
                                   "username": link.substring(1),
                                   "profileImage": ""
                               })
            } else if (link[0] === "#") {

                pageStack.pop(pageStack.find(function(page) {
                    var check = page.isFirstPage === true;
                    if (check)
                        page.onLinkActivated(link)
                    return check;
                }));

                send(link)
            } else {
                pageStack.push(Qt.resolvedUrl("../Browser.qml"), {"href" : link})
            }


        }
        text: tweet.richText
        textFormat:Text.StyledText
        linkColor : (pressed ? Theme.primaryColor : Theme.highlightColor)
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSizeSmall
        color: (pressed ? Theme.highlightColor : Theme.primaryColor)
    }
    MediaBlock {
        id: media
        anchors {
            left: lblText.left
            right: parent.right
            top: lblText.bottom
            topMargin: Theme.paddingSmall
            rightMargin: Theme.paddingLarge
        }
        model: (tweet.media ? tweet.media : [])
        width: lblText.width
        height: model.count ? 100 : 0
    }
    Rectangle {
        visible: tweet.is_quote_status
        anchors.fill: loader
        opacity: 0.3
        radius: 2
        color: Theme.highlightDimmerColor

    }
    Loader {
        id: loader
        width: parent.width
        height: childrenRect.height
        anchors {
            left: media.left
            leftMargin: Theme.paddingSmall
            right: media.right
            rightMargin: Theme.paddingSmall
            top: media.bottom
            topMargin: Theme.paddingSmall
        }
    }

    Component.onCompleted: {
        if (tweet.is_quote_status) {
            loader.setSource("CmpTweet.qml", {miniDisplayMode: true, tweet: tweet.quoted_status});
            //loader.height = loader.childrenRect.height
        }
    }

    onClicked: {
        if(pageStack.depth > 1) {
            pageStack.replace(Qt.resolvedUrl("../TweetDetails.qml"), { "tweet": tweet })
        } else {
            pageStack.push(Qt.resolvedUrl("../TweetDetails.qml"), { "tweet": tweet })
        }
    }

    ContextMenu {
        id: mnu

        MenuItem {
            text: tweet.favorited ? qsTr("Unfavorite") : qsTr("Favorite")
            onClicked: {
                var msg = {
                    'headlessAction': 'favorites_' + (tweet.favorited ? 'destroy' : 'create'),
                    'params': {'id': tweet.id_str}
                };
                Logic.mediator.publish("bgCommand", msg)
                tweet.favorited = !tweet.favorited
            }
            Image {
                id: icFA
                anchors {
                    leftMargin: Theme.horizontalPageMargin
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                width: Theme.iconSizeExtraSmall
                height: width
                source: "image://theme/icon-s-favorite?" + (!tweet.favorited ? Theme.highlightColor : Theme.primaryColor)
            }
            Label {
                anchors {
                    left: icFA.right
                    leftMargin: Theme.paddingMedium
                    verticalCenter: parent.verticalCenter
                }
                text: tweet.favoriteCount
                font.pixelSize: Theme.fontSizeExtraSmall
                color: !tweet.favorited ? Theme.highlightColor : Theme.primaryColor
            }
        }
        MenuItem {
            text: qsTr("Retweet")
            enabled: !tweet.retweeted
            onClicked: {
                var msg = {
                    'headlessAction': 'statuses_retweet_ID',
                    'params': {'id': tweet.id_str}
                };
                Logic.mediator.publish("bgCommand", msg)
                tweet.retweeted = true;
            }
            Image {
                id: icRT
                anchors {
                    leftMargin: Theme.horizontalPageMargin
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                width: Theme.iconSizeExtraSmall
                height: width
                source: "image://theme/icon-s-retweet?" + (!tweet.retweeted ? Theme.highlightColor : Theme.primaryColor)
            }
            Label {
                anchors {
                    left: icRT.right
                    leftMargin: Theme.paddingMedium
                    verticalCenter: parent.verticalCenter
                }
                text: tweet.retweetCount
                font.pixelSize: Theme.fontSizeExtraSmall
                color: !tweet.retweeted ? Theme.highlightColor : Theme.primaryColor
            }
        }
    }
    onPressAndHold: {
        mnu.show(delegate)
    }





}