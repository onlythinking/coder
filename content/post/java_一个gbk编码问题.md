---
title: "记录一个关于 GBK 编码的问题"
date: 2022-10-13T16:09:27+08:00
description: "记录一个关于 GBK 编码的问题"
tags: ["java","GBK","gbk"]
categories: ["java"]
keywords: ["GBK","gbk","java"]
draft: false
---



# 背景

**区分 UTF-8 和 GBK** 

GBK 是在国家标准 GB2312 基础上扩容后兼容 GB2312 的标准，专门用来解决中文编码的，是双字节的，不论中英文都是双字节的。

UTF-8 是一种国际化的编码方式，包含了世界上大部分的语种文字（简体中文字、繁体中文字、英文、日文、韩文等语言），也兼容 ASCII 码。

虽然 GBK 比 UTF-8 少节省两个字节，但是 GBK 只包含中文，UTF-8 则包含全世界所有国家需要用到的字符，所以现在很多系统或者框架处理都默认使用 UTF-8 。

不过业务开发对接系统接口的时候，经常会碰到一些老系统使用 GBK 编码，特别是国内支付，这个时候需要兼容 GBK 和 UTF-8 编码。



# 如何让项目兼容 UTF-8 和 GBK

我们使用 spring boot 2.7 版本。我们默认API使用 UTF-8 ，特别的 API 使用 GBK。在 spring boot 中，当收到请求解析前会通过 `CharacterEncodingFilter` 进行内容编码格式指定。

```java
	@Override
	protected void doFilterInternal(
			HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
			throws ServletException, IOException {

		String encoding = getEncoding();
		if (encoding != null) {
      // 请求进来设置编码（设置了请求强制转编码或请求头未设置编码时）
			if (isForceRequestEncoding() || request.getCharacterEncoding() == null) {
				request.setCharacterEncoding(encoding);
			}
      // 设置了响应强制转编码
			if (isForceResponseEncoding()) {
				response.setCharacterEncoding(encoding);
			}
		}
		filterChain.doFilter(request, response);
	}

```

通过以下方式可以修改项目全局的编码方式

```yaml
server:
  servlet:
    encoding:
      charset: UTF-8
      force-request: false
      force-response: false
```



看下默认情况下，编码格式 UTF-8 并且每次都强制转换，什么意思？也就是就算你请求头 `application/json;charset=GBK` 这样也不会按照头的编码解析，会强制给你转成 UTF-8，如果是 GBK 过来的内容，你就等着吃乱码吧！

```java

	@Bean
	@ConditionalOnMissingBean
	public CharacterEncodingFilter characterEncodingFilter() {
		CharacterEncodingFilter filter = new OrderedCharacterEncodingFilter();
		filter.setEncoding(this.properties.getCharset().name());
		filter.setForceRequestEncoding(this.properties.shouldForce(Encoding.Type.REQUEST));
		filter.setForceResponseEncoding(this.properties.shouldForce(Encoding.Type.RESPONSE));
		return filter;
	}

public boolean shouldForce(Type type) {
		Boolean force = (type != Type.REQUEST) ? this.forceResponse : this.forceRequest;
		if (force == null) {
			force = this.force;
		}
		if (force == null) {
			force = (type == Type.REQUEST);
		}
		return force;
	}
```



现在有一个支付系统，它请求的内容是 GBK 编码，并且有 GET 和 POST 两种方式过来，我们系统接口默认是 UTF-8，所以只有针对特定的 GBK 接口进行处理。需要支持下面几种请求情况。

1. POST 对方的请求内容 GBK 编码并且请求头里指定了编码方式 `application/json;charset=GBK`。
2. POST 对方的请求内容 GBK 编码并且请求头里未指定编码方式 `application/json`。
3. GET 对方的请求内容 GBK 编码。



第一种情况，我们只需要关闭强制转换，带了charset=gbk，就会使用 gbk 编码进行解析，默认不带则使用 utf-8 解析。

```yml
server:
  servlet:
    encoding:
			force: false
```

第二种和第三种情况，我们需要先关闭强制转换，然后添加一个优先级很高的过滤器将指定的请求设置为 GBK 编码格式（也就是在进入spring 解析前就要处理），如果使用 tomcat 容器的话如下处理。

```java
@Slf4j
@Configuration
public class GBKFilterConfig {
    @Bean
    public FilterRegistrationBean gbkFilter() {
        FilterRegistrationBean registration = new FilterRegistrationBean();
        registration.setDispatcherTypes(DispatcherType.REQUEST);
        registration.setFilter(new Filter() {
            @Override
            public void init(javax.servlet.FilterConfig filterConfig) throws ServletException {
            }

            @Override
            public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
                    throws IOException, ServletException {
                RequestFacade req = (RequestFacade) request;
                Class clazz = req.getClass();
                log.info("GBK Filter...");
                try {
                    Field field = clazz.getDeclaredField("request");
                    field.setAccessible(true);
                    Request r = (Request) field.get(req);
                    org.apache.coyote.Request p = r.getCoyoteRequest();
                    // GET 请求参数强使用 GBK 编码。
                    p.getParameters().setQueryStringCharset(Charset.forName("GBK"));
                    // POST 请求带头未指定编码，强制使用 GBK
                    p.getParameters().setCharset(Charset.forName("GBK"));
                    p.setCharset(Charset.forName("GBK"));
                    chain.doFilter(request, response);
                } catch (Exception e) {
                   log.error("error", e)
                }
            }

            @Override
            public void destroy() {
            }
        });
        registration.addUrlPatterns("/api/gbk/**");
        registration.setName("gbkFilter");
        registration.setOrder(Integer.MIN_VALUE);
        return registration;
    }
}
```

