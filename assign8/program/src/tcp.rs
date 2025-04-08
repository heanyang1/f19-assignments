extern crate rand;

use crate::session::*;
use std::{collections::HashSet, mem::transmute};

pub struct Syn;
pub struct SynAck;
pub struct Ack;
pub struct Fin;

pub type TCPHandshake<TCPRecv> = Recv<Syn, Send<SynAck, Recv<Ack, TCPRecv>>>;

pub type TCPRecv<TCPClose> = Rec<Recv<Vec<Packet>, Send<Vec<usize>, Offer<Var<Z>, TCPClose>>>>;

pub type TCPClose = Send<Ack, Send<Fin, Recv<Ack, Close>>>;

pub type TCPServer = TCPHandshake<TCPRecv<TCPClose>>;

pub type TCPClient = <TCPServer as HasDual>::Dual;

pub fn tcp_server(c: Chan<(), TCPServer>) -> Vec<Buffer> {
  // handshake
  let (c, Syn) = c.recv();
  let c = c.send(SynAck);
  let (c, Ack) = c.recv();

  fn receive(c: Chan<(), TCPRecv<TCPClose>>) -> (Vec<Buffer>, Chan<(), TCPClose>) {
    let mut c = c.rec_push();
    let mut bufs: Vec<(Buffer, usize)> = Vec::new();
    loop {
      c = {
        let (c, packets) = c.recv();
        let mut nums = Vec::new();
        for packet in packets {
          nums.push(packet.seqno);
          bufs.push((packet.buf, packet.seqno));
        }
        let c = c.send(nums);
        match c.offer() {
          Branch::Left(c) => c.rec_pop(),
          Branch::Right(c) => unsafe {
            bufs.sort_by(|a, b| a.1.cmp(&b.1));
            return (bufs.into_iter().map(|b| b.0).collect(), transmute(c));
          },
        }
      }
    }
  }
  let (bufs, c) = receive(c);

  // close
  let c = c.send(Ack);
  let c = c.send(Fin);
  let (c, Ack) = c.recv();
  c.close();
  bufs
}

pub fn tcp_client(c: Chan<(), TCPClient>, bufs: Vec<Buffer>) {
  // handshake
  let c = c.send(Syn);
  let (c, SynAck) = c.recv();
  let c = c.send(Ack);

  fn send(
    c: Chan<(), <TCPRecv<TCPClose> as HasDual>::Dual>,
    bufs: Vec<Buffer>,
  ) -> Chan<(), <TCPClose as HasDual>::Dual> {
    let mut c = c.rec_push();
    let mut not_sent = HashSet::new();
    for (i, _) in bufs.iter().enumerate() {
      not_sent.insert(i);
    }
    loop {
      c = {
        let packets: Vec<Packet> = not_sent
          .iter()
          .map(|i| Packet {
            seqno: *i,
            buf: bufs[*i].clone(),
          })
          .collect();
        let c = c.send(packets);
        let (c, nums) = c.recv();
        for num in nums {
          not_sent.remove(&num);
        }
        if not_sent.is_empty() {
          unsafe { return transmute(c.right()) }
        } else {
          c.left().rec_pop()
        }
      }
    }
  }
  let c = send(c, bufs);

  // close
  let (c, Ack) = c.recv();
  let (c, Fin) = c.recv();
  let c = c.send(Ack);
  c.close();
}

#[cfg(test)]
mod test {
  use crate::session::NOISY;
  use crate::session::*;
  use crate::tcp::*;
  use rand;
  use rand::Rng;
  use std::sync::atomic::Ordering;
  use std::thread;

  fn gen_bufs() -> Vec<Buffer> {
    let mut bufs: Vec<Buffer> = Vec::new();
    let mut rng = rand::thread_rng();
    for _ in 0usize..20 {
      let buf: Buffer = vec![0; rng.gen_range(1..10)];
      let buf: Buffer = buf.into_iter().map(|_| rng.gen()).collect();
      bufs.push(buf);
    }
    bufs
  }

  #[test]
  fn test_basic() {
    let bufs = gen_bufs();
    let bufs_copy = bufs.clone();
    let (s, c): (Chan<(), TCPServer>, Chan<(), TCPClient>) = Chan::new();
    let thread = thread::spawn(move || {
      tcp_client(c, bufs);
    });

    let recvd = tcp_server(s);
    thread.join().unwrap();

    assert_eq!(recvd, bufs_copy);
  }

  #[test]
  fn test_lossy() {
    let bufs = gen_bufs();
    let bufs_copy = bufs.clone();

    NOISY.with(|noisy| {
      noisy.store(true, Ordering::SeqCst);
    });

    let (s, c): (Chan<(), TCPServer>, Chan<(), TCPClient>) = Chan::new();
    let thread = thread::spawn(move || {
      tcp_client(c, bufs);
    });

    let recvd = tcp_server(s);
    thread.join().unwrap();

    assert_eq!(recvd, bufs_copy);
  }
}
