use future::*;
use std::fs;
use std::io;
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::thread;

pub struct FileReader {
    path: PathBuf,
    thread: Option<thread::JoinHandle<io::Result<String>>>,
    done_flag: Arc<AtomicBool>,
}

impl FileReader {
    pub fn new(path: PathBuf) -> FileReader {
        FileReader {
            path,
            thread: None,
            done_flag: Arc::new(AtomicBool::new(false)),
        }
    }
}

impl Future for FileReader {
    type Item = io::Result<String>;

    fn poll(&mut self) -> Poll<Self::Item> {
        if self.thread.is_none() {
            let path = self.path.clone();
            let done = self.done_flag.clone();
            self.thread.replace(thread::spawn(move || {
                let s = fs::read_to_string(path).unwrap();
                done.store(true, Ordering::SeqCst);
                Ok(s)
            }));
            Poll::NotReady
        } else {
            if self.done_flag.load(Ordering::SeqCst) {
                Poll::Ready(self.thread.take().unwrap().join().unwrap())
            } else {
                Poll::NotReady
            }
        }
    }
}
