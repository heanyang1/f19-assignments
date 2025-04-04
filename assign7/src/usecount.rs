use std::ops::{Deref, DerefMut};

pub struct UseCounter<T> {
    count: *mut u32,
    value: *mut T,
}

impl<T> UseCounter<T> {
    pub fn new(value: T) -> UseCounter<T> {
        UseCounter {
            count: Box::into_raw(Box::new(0)),
            value: Box::into_raw(Box::new(value)),
        }
    }

    pub fn count(&self) -> u32 {
        unsafe { *self.count }
    }
}

impl<T> Drop for UseCounter<T> {
    fn drop(&mut self) {
        unsafe {
            drop(Box::from_raw(self.value));
            drop(Box::from_raw(self.count));
        }
    }
}

impl<T> Deref for UseCounter<T> {
    type Target = T;

    fn deref(&self) -> &T {
        unsafe {
            *self.count += 1;
            &*self.value
        }
    }
}

impl<T> DerefMut for UseCounter<T> {
    fn deref_mut(&mut self) -> &mut T {
        unsafe {
            *self.count += 1;
            &mut *self.value
        }
    }
}

unsafe impl<T> Send for UseCounter<T> {}
