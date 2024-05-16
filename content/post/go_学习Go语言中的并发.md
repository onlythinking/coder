---
title: "学习Go语言并发编程"
date: 2024-05-14T18:15:22+08:00
description: "探索Go语言中的并发编程。了解goroutine、channel以及各种并发设计模式，通过详细的示例学习如何在Go语言中高效实现并发任务。提升你的Go编程技能，掌握并发处理的最佳实践。"
tags: ["并发"]
categories: ["go"]
keywords: [
  "Go语言并发",
  "Go并发编程",
  "Go语言goroutine",
  "Go语言channel",
  "并发编程教程",
  "Golang并发示例",
  "Golang并发设计模式",
  "Go语言并发任务",
  "高并发Go编程",
  "Golang工作池",
  "Golang并发处理",
  "Go并发IO操作"
]
draft: false
---

# 关于并发

Go 语言的创始人**Rob Pike** 曾说过：并行关乎执行，并发关乎结构。他认为：
•  并发是一种程序设计方法：将一个程序分解成多个小片段，每个小片段独立执行；并发程序的小片段之间可以通过**通信**相互协作。
•  并行是有关执行的，它表示同时进行一些计算任务。

程序小片段之间通讯不同语言实现不同，比如：传统语言Java使用**共享内存**方式达到线程之间通讯，而Go语言**channel**来进行通讯。



# 原生线程、Java线程、Goroutine

Java中的多线程，由 JVM 在 Java 堆中分配内存来存储线程的相关信息，包括线程栈、程序计数器等。当需要执行 Java 线程时，它会向操作系统请求分配一个或多个原生线程（例如 POSIX 线程或 Windows 线程），操作系统分配成功后，JVM 会将 Java 线程与这些原生线程进行映射，并建立关联，并在需要时将 Java 线程的状态同步到相应的原生线程中。

由此可以看出，Java线程和原生线程**1:1**对应，由操作系统（OS）调度算法执行，该并发以下特点：

- 线程栈默认空间大且不支持动态伸缩，Java 默认最小都是1MB，Linux 默认 8MB；
- 线程切换创建、销毁以及线程间上下文切换的代价都较大。
- 线程通过共享内存进行通讯，



> POSIX线程（Pthreads）是C函数、类型和常数的集合，用于创建和管理线程。它是POSIX标准的一个子集，提供在BeagleBone Black上使用C/C++应用程序实现线程所需的一切。
>
> 原生线程就是操作系统线程或叫系统线程。



Go语言引入用户层轻量级线程（Goroutine），它由Go运行时负责调度。Goroutine相比传统操作系统线程而言有如下优势。

- 资源占用小，每个Goroutine的初始栈大小仅为2KB，且支持动态伸缩，避免内存浪费；
- 由Go运行时而不是操作系统调度，goroutine上下文切换代价较小；
- 内置**channel**作为goroutine间通信原语，为并发设计提供强大支撑。



# 了解Go调度原理

Go 语言实现了调度器（scheduler），它负责将 goroutine 分配到原生线程上执行。

## G-P-M模型

Go 语言中的**调度模型（G-P-M模型）**它包含了三个重要组件：G（goroutine）、P（processor）、M（machine）。

![GPM](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/202405151522873.jpeg)

- **G（goroutine）**：一个执行单元，这里也就是 goroutine，它包含了执行代码所需的信息，比如栈空间、程序计数器等。

- **P（processor）**：P 一个逻辑处理器，它负责执行 goroutine。每个 P 维护了一个 goroutine 队列，它可以将 goroutine 分配到 M（系统线程）上执行。P 的数量由 GOMAXPROCS 环境变量决定，默认值为 CPU 的逻辑核心数。

- **M（machine）**：一个系统线程（machine），它负责执行 goroutine 的真正计算工作。M 与操作系统的线程直接绑定，负责实际的计算任务，比如执行 goroutine 的函数、系统调用等。Go 语言的调度器会将多个 goroutine 映射到少量的系统线程上执行。



## 抢占式调度

在上面模型中，如果某个G处于死循环或长时间执行（比如：进行系统调用，IO操作），那么P队列里面的G就长时间得不到执行，为了解决此问题，需要使用抢占式调度。

Java 中有以下两种抢占式调度算法

1. **优先级调度（Priority Scheduling）**：
   - 每个线程都有一个优先级，高优先级的线程会比低优先级的线程更容易获得CPU的执行权（注意：设置了优先级不是绝对优先执行，只是概率上高）。
   - 在Java中，线程的优先级范围是从`Thread.MIN_PRIORITY`（1）到`Thread.MAX_PRIORITY`（10），默认是`Thread.NORM_PRIORITY`（5）。
2. **时间片轮转调度（Round Robin Scheduling）**：
   - 每个线程被分配一个固定的时间片，当该线程的时间片用完时，操作系统会暂停它的执行，将CPU控制权交给下一个线程。
   - 在Java中，时间片轮转调度通过`yield()`方法来实现。当线程调用`yield()`时，它就会主动放弃CPU的执行权，让其他线程有机会执行。



Go 语言与Java抢占调度不同，Java是实际上是操作系统时间片轮转调度，发生在内核层。Go 抢占调度是发生在用户层，由 Go 运行时管理，通过软件定时器和抢占点来实现抢占。

Go 程序启动时会创建一个线程（称为监控线程），该线程运行一个内部函数 `sysmon` ，用来进行系统监控任务，如垃圾回收、抢占调度、监视死锁等。这个函数在后台运行，确保 Go 程序的正常运行。

```go
func main() {
  ...
	if GOARCH != "wasm" { 
     // 系统栈上的函数执行
		systemstack(func() {  
			newm(sysmon, nil, -1) // 用于创建新的 M（机器，代表一个操作系统线程）。
		})
	} 
  ...
}
```

 `sysmon`  每20us~10ms启动一次，大体工作：

- 释放闲置超过5分钟的span物理内存；
- 如果超过2分钟没有垃圾回收，强制执行；
- 将长时间未处理的netpoll结果添加到任务队列；
- 向长时间运行的G任务发出抢占调度；
- 收回因syscall长时间阻塞的P。



具体来说，以下情况会触发抢占式调度：

1. **系统调用**：当一个 goroutine 执行系统调用时，调度器会将该 goroutine 暂停，并将处理器分配给其他可运行的 goroutine。一旦系统调用完成，被暂停的 goroutine 可以继续执行。
2. **函数调用**：当一个 goroutine 调用一个阻塞的函数（如通道的发送和接收操作、锁的加锁和解锁操作等）时，调度器会将该 goroutine 暂停，并将处理器分配给其他可运行的 goroutine。一旦被阻塞的函数可以继续执行，被暂停的 goroutine 可以继续执行。
3. **时间片耗尽**：每个 goroutine 在运行一段时间后都会消耗一个时间片。当时间片耗尽时，调度器会将当前正在运行的 goroutine 暂停，并将处理器分配给其他可运行的 goroutine。被暂停的 goroutine 将会被放入到就绪队列中，等待下一次调度。



# GO并发模型

Go 使用 CSP（Communicating Sequential Processes，通信顺序进程）并发编程模型，该模型由计算机科学家 Tony Hoare 在 1978 年提出。

在Go中，针对CSP模型提供了三种并发原语：

- **goroutine**：对应CSP模型中的P（原意是进程，在这里也就是goroutine），封装了数据的处理逻辑，是Go运行时调度的基本执行单元。
- **channel**：对应CSP模型中的输入/输出原语，用于goroutine之间的通信和同步。
- **select**：用于应对多路输入/输出，可以让goroutine同时协调处理多个channel操作。

Go 奉行“**不要通过共享内存来通信，而应通过通信来共享内存。**”，也就是推荐通过channel来传递值，让goroutine相互通讯协作。

channel 分为无缓冲和有缓冲，使用通道时遵循以下规范：

1. 在无缓冲通道上，每一次发送操作都有对应匹配的接收操作。
2. 对于从无缓冲通道进行的接收，发生在对该通道进行的发送完成之前。
3. 对于带缓冲的通道（缓存大小为C），通道中的第K个接收完成操作发生在第K+C个发送操作完成之前。
4. 如果将C=0就是无缓冲的通道，也就是第K个接收完成在第K个发送完成之前。

```go
func sender(ch chan<- int, done chan<- bool) {
	fmt.Println("Sending...")
	ch <- 42 // 发送数据到无缓冲通道
	fmt.Println("Sent")
	done <- true // 发送完成信号
}

func receiver(ch <-chan int, done <-chan bool) {
	<-done // 等待发送操作完成信号
	fmt.Println("Receiving...")
	val := <-ch // 从无缓冲通道接收数据
	fmt.Println("Received:", val)
}

func main() {
	ch := make(chan int) // 创建无缓冲通道
	done := make(chan bool) // 用于发送操作完成信号

	go sender(ch, done)   // 启动发送goroutine
	go receiver(ch, done) // 启动接收goroutine

	time.Sleep(2 * time.Second) // 等待一段时间以观察结果
}

```

有缓冲通道

```go
func sender(ch chan<- int) {
	for i := 0; i < 5; i++ {
		fmt.Println("Sending:", i)
		ch <- i // 发送数据到通道
		fmt.Println("Sent:", i)
	}
	close(ch)
}

func receiver(ch <-chan int) {
	for {
		val, ok := <-ch // 从通道接收数据
		if !ok {
			fmt.Println("Channel closed")
			return
		}
		fmt.Println("Received:", val)
		time.Sleep(1 * time.Second) // 模拟接收操作耗时
	}
}

func main() {
	ch := make(chan int, 2) // 创建带缓冲大小为2的通道

	go sender(ch)   // 启动发送goroutine
	go receiver(ch) // 启动接收goroutine

	time.Sleep(10 * time.Second) // 等待一段时间以观察结果
}

```



# Go并发场景

## 并行计算

利用goroutine并发执行任务，加速计算过程。

```go
// calculateSquare 是一个计算数字平方的函数，它模拟了一个耗时的计算过程。
func calculateSquare(num int, resultChan chan<- int) {
	time.Sleep(1 * time.Second) // 模拟耗时计算
	resultChan <- num * num
}

func main() {
	nums := []int{1, 2, 3, 4, 5}
	resultChan := make(chan int)

	// 启动多个goroutine并发计算数字的平方
	for _, num := range nums {
		go calculateSquare(num, resultChan)
	}

	// 从通道中接收计算结果并打印
	for range nums {
		result := <-resultChan
		fmt.Println("Square:", result)
	}
	close(resultChan)
}

```



## IO密集型任务

在处理IO密集型任务时，可以使用goroutine和channel实现并发读写操作，提高IO效率。

```go

// fetchURL 函数用于获取指定URL的内容，并将结果发送到通道resultChan中。
func fetchURL(url string, resultChan chan<- string) {
	resp, err := http.Get(url)
	if err != nil {
		resultChan <- fmt.Sprintf("Error fetching %s: %s", url, err)
		return
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		resultChan <- fmt.Sprintf("Error reading response from %s: %s", url, err)
		return
	}
	resultChan <- string(body)
}

func main() {
	urls := []string{"https://example.com", "https://example.org", "https://example.net"}
	resultChan := make(chan string)

	// 启动多个goroutine并发获取URL的内容
	for _, url := range urls {
		go fetchURL(url, resultChan)
	}

	// 从通道中接收结果并打印
	for range urls {
		result := <-resultChan
		fmt.Println("Response:", result)
	}
	close(resultChan)
}

```



## 并发数据处理

对于需要同时处理多个数据流的情况，可以使用goroutine和channel实现并发数据处理，例如数据流的合并、拆分、过滤等操作。

```go
// processData 函数用于处理从dataStream中接收的数据，并将处理结果发送到resultChan中。
func processData(dataStream <-chan int, resultChan chan<- int) {
	for num := range dataStream {
		resultChan <- num * 2 // 假设处理数据是将数据乘以2
	}
}

func main() {
	dataStream := make(chan int)
	resultChan := make(chan int)

	// 产生数据并发送到dataStream中
	go func() {
		for i := 1; i <= 5; i++ {
			dataStream <- i
		}
		close(dataStream)
	}()

	// 启动goroutine并发处理数据
	go processData(dataStream, resultChan)

	// 从通道中接收处理结果并打印
	for range dataStream {
		result := <-resultChan
		fmt.Println("Processed Data:", result)
	}
	close(resultChan)
}

```

## 并发网络编程

编写网络服务器或客户端时，可以利用goroutine处理每个连接，实现高并发的网络应用。

```go
// handler 是一个HTTP请求处理函数，它会向客户端发送"Hello, World!"的响应。
func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello, World!")
}

func main() {
	// 注册HTTP请求处理函数
	http.HandleFunc("/", handler)

	// 启动HTTP服务器并监听端口8080
	go http.ListenAndServe(":8080", nil)
	fmt.Println("Server started on port 8080")

	// 使用select{}使主goroutine保持运行状态，以便HTTP服务器能够处理请求
	select {}
}

```

## 定时任务和周期性任务

```go
// task 是一个需要定时执行的任务函数。
func task() {
	fmt.Println("Task executed at:", time.Now())
}

func main() {
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()

	// 循环等待定时器的触发并执行任务
	for {
		select {
		case <-ticker.C:
			task()
		}
	}
}
```



## 工作池

通过创建一组goroutine来处理任务池中的任务，可以有效地控制并发数量，适用于需要限制并发的情况。

```go
// worker 是一个工作函数，它会从jobs通道中接收任务，并将处理结果发送到results通道中。
func worker(id int, jobs <-chan int, results chan<- int) {
	for job := range jobs {
		fmt.Printf("Worker %d started job %d\n", id, job)
		time.Sleep(1 * time.Second) // 模拟工作时间
		fmt.Printf("Worker %d finished job %d\n", id, job)
		results <- job * 2 // 假设工作的结果是输入的两倍
	}
}

func main() {
	const numJobs = 10
	const numWorkers = 3

	jobs := make(chan int, numJobs)    // 缓冲channel用于发送任务
	results := make(chan int, numJobs) // 用于接收任务结果

	// 启动多个worker goroutine
	var wg sync.WaitGroup
	for i := 1; i <= numWorkers; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			worker(id, jobs, results)
		}(i)
	}

	// 发送任务到jobs channel
	for j := 1; j <= numJobs; j++ {
		jobs <- j
	}
	close(jobs) // 关闭jobs channel

	// 等待所有worker完成并收集结果
	go func() {
		wg.Wait()
		close(results)
	}()

	// 从通道中接收处理结果并打印
	for result := range results {
		fmt.Println("Result:", result)
	}
}
```

