<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:atom="http://www.w3.org/2005/Atom"
  xmlns:content="http://purl.org/rss/1.0/modules/content/">
  <xsl:output method="html" indent="yes" encoding="UTF-8"/>

  <xsl:template match="/">
    <html lang="zh-CN">
    <head>
      <meta charset="UTF-8"/>
      <meta name="viewport" content="width=device-width, initial-scale=1"/>
      <title><xsl:value-of select="rss/channel/title"/> - RSS 订阅</title>
      <style>
        body { font-family: -apple-system, "PingFang SC", "Microsoft YaHei", sans-serif; max-width: 900px; margin: 0 auto; padding: 20px; background: #f8f5ec; color: #34495e; }
        h1 { border-bottom: 3px solid #1a1a3e; padding-bottom: 10px; color: #1a1a3e; }
        .channel-desc { color: #666; margin-bottom: 30px; }
        .item { background: #fff; border-radius: 8px; padding: 20px; margin-bottom: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.08); }
        .item h2 { margin: 0 0 8px; font-size: 18px; }
        .item h2 a { color: #1a1a3e; text-decoration: none; }
        .item h2 a:hover { color: #c05b4d; }
        .item-meta { font-size: 12px; color: #999; margin-bottom: 10px; }
        .item-desc { color: #555; line-height: 1.6; font-size: 14px; }
        .item-desc img { max-width: 100%; height: auto; }
        .item-desc pre { background: #f6f6f6; padding: 12px; border-radius: 4px; overflow-x: auto; font-size: 12px; }
        .read-more { display: inline-block; margin-top: 10px; color: #c05b4d; font-size: 14px; }
        .footer { text-align: center; color: #aaa; font-size: 12px; margin-top: 40px; padding-top: 20px; border-top: 1px solid #e0e0e0; }
      </style>
    </head>
    <body>
      <h1><xsl:value-of select="rss/channel/title"/></h1>
      <p class="channel-desc"><xsl:value-of select="rss/channel/description"/></p>

      <xsl:for-each select="rss/channel/item">
        <div class="item">
          <h2><a href="{link}" target="_blank"><xsl:value-of select="title"/></a></h2>
          <div class="item-meta">
            <xsl:value-of select="pubDate"/> |
            作者：<xsl:value-of select="author"/>
          </div>
          <div class="item-desc">
            <xsl:value-of select="description" disable-output-escaping="yes"/>
          </div>
          <a class="read-more" href="{link}" target="_blank">阅读更多 →</a>
        </div>
      </xsl:for-each>

      <div class="footer">
        <p>使用 RSS 阅读器订阅此源：<code><xsl:value-of select="rss/channel/link"/></code></p>
        <p>Powered by Hugo | <a href="/">返回博客首页</a></p>
      </div>
    </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
