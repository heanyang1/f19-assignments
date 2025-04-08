use crate::backend::{login, order, UserId};
use std::marker::PhantomData;

pub struct Cart {
  _secret: (),
}
pub struct Empty {
  _secret: (),
}
pub struct NonEmpty {
  _secret: (),
}
pub struct Checkout {
  _secret: (),
  user: UserId,
  items: Vec<f64>,
}

pub struct Buying<T> {
  _marker: PhantomData<T>,
  user: UserId,
  items: Vec<f64>,
}

impl Cart {
  pub fn login(username: String, password: String) -> Result<Buying<Empty>, String> {
    match login(username, password) {
      Ok(user) => Ok(Buying {
        _marker: PhantomData,
        user,
        items: Vec::new(),
      }),
      Err(err) => Err(err),
    }
  }
}

impl<T> Buying<T> {
  pub fn additem(mut self, price: f64) -> Buying<NonEmpty> {
    self.items.push(price);
    Buying {
      _marker: PhantomData,
      user: self.user,
      items: self.items,
    }
  }
}

impl Buying<NonEmpty> {
  pub fn clearitems(self) -> Buying<Empty> {
    Buying {
      _marker: PhantomData,
      user: self.user,
      items: Vec::new(),
    }
  }

  pub fn checkout(self) -> Checkout {
    Checkout {
      _secret: (),
      user: self.user,
      items: self.items,
    }
  }
}

impl Checkout {
  pub fn cancel(self) -> Buying<NonEmpty> {
    Buying {
      _marker: PhantomData,
      user: self.user,
      items: self.items,
    }
  }

  pub fn order(self) -> Result<Buying<Empty>, (Checkout, String)> {
    match order(&self.user, self.items.iter().sum()) {
      Ok(_) => Ok(Buying {
        _marker: PhantomData,
        user: self.user,
        items: Vec::new(),
      }),
      Err(err) => Err((self, err)),
    }
  }
}
