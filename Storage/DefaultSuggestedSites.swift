/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public class DefaultSuggestedSites {
    public static let sites = [
        "default": [
            SuggestedSiteData(
                url: "https://www.google.com",
                bgColor: "e6e6e6",
                imageUrl: "asset://suggestedsites_google",
                faviconUrl: "asset://braveLogo",
                trackingId: 632,
                title: NSLocalizedString("Google", comment: "Tile title for Google")
            ),
            SuggestedSiteData(
                url: "https://www.yahoo.com",
                bgColor: "ffffff",
                imageUrl: "asset://suggestedsites_yahoo",
                faviconUrl: "asset://braveLogo",
                trackingId: 632,
                title: NSLocalizedString("Yahoo", comment: "Tile title for Yahoo")
            ),
            SuggestedSiteData(
                url: "https://m.facebook.com/",
                bgColor: "6685cd",
                imageUrl: "asset://suggestedsites_facebook",
                faviconUrl: "asset://defaultFavicon",
                trackingId: 632,
                title: NSLocalizedString("Facebook", comment: "Tile title for Facebook")
            ),
            SuggestedSiteData(
                url: "https://m.youtube.com/",
                bgColor: "0xcd201f",
                imageUrl: "asset://suggestedsites_youtube",
                faviconUrl: "asset://defaultFavicon",
                trackingId: 631,
                title: NSLocalizedString("YouTube", comment: "Tile title for YouTube")
            ),
            SuggestedSiteData(
                url: "https://www.amazon.com/",
                bgColor: "0x666666",
                imageUrl: "asset://suggestedsites_amazon",
                faviconUrl: "asset://defaultFavicon",
                trackingId: 630,
                title: NSLocalizedString("Amazon", comment: "Tile title for Amazon")
            ),
            SuggestedSiteData(
                url: "https://mobile.twitter.com/",
                bgColor: "ffffff",
                imageUrl: "asset://suggestedsites_twitter",
                faviconUrl: "asset://defaultFavicon",
                trackingId: 628,
                title: NSLocalizedString("Twitter", comment: "Tile title for Twitter")
            ),
            SuggestedSiteData(
                url: "https://www.wikipedia.org/",
                bgColor: "e6e6e6",
                imageUrl: "asset://suggestedsites_wiki",
                faviconUrl: "asset://defaultFavicon",
                trackingId: 629,
                title: NSLocalizedString("Wikipedia", comment: "Tile title for Wikipedia")
            ),
            SuggestedSiteData(
                url: "https://www.duckduckgo.com/?t=brave",
                bgColor: "ffffff",
                imageUrl: "asset://suggestedsites_DDG",
                faviconUrl: "asset://braveLogo",
                trackingId: 632,
                title: NSLocalizedString("DuckDuckGo", comment: "Tile title for DDG")
            )
        ]
    ]
}
