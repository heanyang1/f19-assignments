use future::{Future, Poll};
use std::mem;
use std::sync::{mpsc, Arc, Mutex};
use std::thread;

/*
 * Core executor interface.
 */

pub trait Executor {
    fn spawn<F>(&mut self, f: F)
    where
        F: Future<Item = ()> + 'static;
    fn wait(&mut self);
}

/*
 * Example implementation of a naive executor that executes futures
 * in sequence.
 */

pub struct BlockingExecutor;

impl BlockingExecutor {
    pub fn new() -> BlockingExecutor {
        BlockingExecutor
    }
}

impl Executor for BlockingExecutor {
    fn spawn<F>(&mut self, mut f: F)
    where
        F: Future<Item = ()>,
    {
        loop {
            if let Poll::Ready(()) = f.poll() {
                break;
            }
        }
    }

    fn wait(&mut self) {}
}

/*
 * Part 2a - Single threaded executor
 */

pub struct SingleThreadExecutor {
    futures: Vec<Box<dyn Future<Item = ()>>>,
}

impl SingleThreadExecutor {
    pub fn new() -> SingleThreadExecutor {
        SingleThreadExecutor { futures: vec![] }
    }
}

impl Executor for SingleThreadExecutor {
    fn spawn<F>(&mut self, mut f: F)
    where
        F: Future<Item = ()> + 'static,
    {
        match f.poll() {
            Poll::Ready(()) => {}
            Poll::NotReady => self.futures.push(Box::new(f)),
        }
    }

    fn wait(&mut self) {
        let futures = mem::replace(&mut self.futures, vec![]);
        for mut f in futures {
            match f.poll() {
                Poll::Ready(()) => {}
                Poll::NotReady => self.futures.push(f),
            }
        }
    }
}

pub struct MultiThreadExecutor {
    sender: mpsc::Sender<Option<Box<dyn Future<Item = ()>>>>,
    threads: Vec<thread::JoinHandle<()>>,
}

impl MultiThreadExecutor {
    pub fn new(num_threads: i32) -> MultiThreadExecutor {
        let (sender, receiver) = mpsc::channel();
        let receiver_ref = Arc::new(Mutex::new(receiver));
        let threads = (0..num_threads)
            .map(|_| {
                let receiver_ref = receiver_ref.clone();
                thread::spawn(move || {
                    let mut executor = SingleThreadExecutor::new();
                    loop {
                        match receiver_ref.lock().unwrap().recv().unwrap() {
                            Some(f) => executor.spawn(f),
                            None => {
                                executor.wait();
                                break;
                            }
                        }
                    }
                })
            })
            .collect();
        MultiThreadExecutor { sender, threads }
    }
}

impl Executor for MultiThreadExecutor {
    fn spawn<F>(&mut self, f: F)
    where
        F: Future<Item = ()> + 'static,
    {
        self.sender.send(Some(Box::new(f))).unwrap();
    }

    fn wait(&mut self) {
        for _ in 0..self.threads.len() {
            self.sender.send(None).unwrap();
        }
        for thread in self.threads.drain(..) {
            thread.join().unwrap();
        }
    }
}
