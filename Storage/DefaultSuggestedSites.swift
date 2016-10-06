/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public class DefaultSuggestedSites {
    public static let sites = [
        "default": [
            SuggestedSiteData(
                url: "https://www.google.com",
                bgColor: "f4f4f4",
                imageUrl: "asset://suggestedsites_google",
                faviconUrl: "asset://braveLogo",
                trackingId: 632,
                title: "Google"
            ),
            SuggestedSiteData(
                url: "https://www.yahoo.com",
                bgColor: "400190",
                imageUrl: "asset://suggestedsites_yahoo",
                faviconUrl: "asset://braveLogo",
                trackingId: 632,
                title: "Yahoo"
            ),
            SuggestedSiteData(
                url: "https://m.facebook.com/",
                bgColor: "475a96",
                imageUrl: "asset://suggestedsites_facebook",
                faviconUrl: "asset://defaultFavicon",
                trackingId: 632,
                title: "Facebook"
            ),
            SuggestedSiteData(
                url: "https://m.youtube.com/",
                bgColor: "c8302a",
                imageUrl: "asset://suggestedsites_youtube",
                faviconUrl: "asset://defaultFavicon",
                trackingId: 631,
                title: "YouTube"
            ),
            SuggestedSiteData(
                url: "https://www.amazon.com/",
                bgColor: "231f20",
                imageUrl: "asset://suggestedsites_amazon",
                faviconUrl: "asset://defaultFavicon",
                trackingId: 630,
                title: "Amazon"
            ),
            SuggestedSiteData(
                url: "https://mobile.twitter.com/",
                bgColor: "2aaae1",
                imageUrl: "asset://suggestedsites_twitter",
                faviconUrl: "asset://defaultFavicon",
                trackingId: 628,
                title: "Twitter"
            ),
            SuggestedSiteData(
                url: "https://www.wikipedia.org/",
                bgColor: "000000",
                imageUrl: "asset://suggestedsites_wikipedia",
                faviconUrl: "asset://defaultFavicon",
                trackingId: 629,
                title: "Wikipedia"
            ),
            SuggestedSiteData(
                url: "https://www.duckduckgo.com/?t=brave",
                bgColor: "f8f8f8",
                imageUrl: "asset://suggestedsites_DDG",
                faviconUrl: "asset://braveLogo",
                trackingId: 632,
                title: "DuckDuckGo"
            )
        ]
    ]
}
