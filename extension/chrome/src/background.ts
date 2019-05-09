import * as LZUTF8 from "lzutf8";

chrome.runtime.onInstalled.addListener(() => {
    chrome.contextMenus.create({
        type: "normal",
        title: "Convert selected text to USM",
        id: "convert-usm",
        contexts: ["selection"]
    });
});

chrome.contextMenus.onClicked.addListener(info => {
    if (info.menuItemId === "convert-usm") {
        chrome.tabs.executeScript(
            {
                code: "window.getSelection().toString();"
            },
            selection => {
                const selected = selection[0];
                chrome.tabs.create({
                    url: `https://textusm.firebaseapp.com/share/viewusm/${encodeURIComponent(
                        LZUTF8.compress(selected, {
                            outputEncoding: "Base64"
                        })
                    )}`,
                    active: true
                });
            }
        );
    }
});
