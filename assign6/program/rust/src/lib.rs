use std::fmt::{Debug, Display};
use std::{fmt, mem};

#[derive(PartialEq, Eq, Clone)]
pub enum BinaryTree<T> {
    Leaf,
    Node(T, Box<BinaryTree<T>>, Box<BinaryTree<T>>),
}

impl<T: Debug + Display + PartialOrd> BinaryTree<T> {
    pub fn len(&self) -> usize {
        match self {
            Self::Leaf => 0,
            Self::Node(_, l, r) => 1 + l.len() + r.len(),
        }
    }

    pub fn to_vec(&self) -> Vec<&T> {
        match self {
            Self::Leaf => vec![],
            Self::Node(t, l, r) => {
                let mut v = l.to_vec();
                v.push(t);
                v.append(&mut r.to_vec());
                v
            }
        }
    }

    pub fn sorted(&self) -> bool {
        let v = self.to_vec();
        v.windows(2).all(|w| w[0] <= w[1])
    }

    pub fn insert(&mut self, t: T) {
        match self {
            Self::Leaf => *self = Self::Node(t, Box::new(Self::Leaf), Box::new(Self::Leaf)),
            Self::Node(v, l, r) => {
                if t < *v {
                    l.insert(t);
                } else {
                    r.insert(t);
                }
            }
        }
    }

    pub fn search(&self, query: &T) -> Option<&T> {
        match self {
            Self::Leaf => None,
            Self::Node(v, l, r) => {
                if query == v {
                    Some(v)
                } else if v < query {
                    r.search(query)
                } else {
                    match l.as_ref() {
                        Self::Leaf => Some(v),
                        _ => l.search(query),
                    }
                }
            }
        }
    }

    fn largest(&mut self) -> &mut Self {
        let mut cur = self;
        loop {
            let right_is_node = match cur {
                Self::Node(_, _, right) => matches!(right.as_ref(), Self::Node(..)),
                _ => false,
            };
            if right_is_node {
                cur = match cur {
                    Self::Node(_, _, right) => right.as_mut(),
                    _ => unreachable!(),
                };
            } else {
                return cur;
            }
        }
    }

    fn smallest(&mut self) -> &mut Self {
        let mut cur = self;
        loop {
            let left_is_node = match cur {
                Self::Node(_, left, _) => matches!(left.as_ref(), Self::Node(..)),
                _ => false,
            };
            if left_is_node {
                cur = match cur {
                    Self::Node(_, left, _) => left.as_mut(),
                    _ => unreachable!(),
                };
            } else {
                return cur;
            }
        }
    }

    fn remove(&mut self) -> Option<T> {
        let old_self = mem::replace(self, Self::Leaf);
        let (val, new_self) = match old_self {
            Self::Leaf => (None, Self::Leaf),
            Self::Node(v, mut l, mut r) => match (l.as_mut(), r.as_mut()) {
                (Self::Leaf, Self::Leaf) => (Some(v), Self::Leaf),
                (Self::Leaf, r_tree) => (Some(v), mem::replace(r_tree, Self::Leaf)),
                (l_tree, _) => (Some(v), mem::replace(l_tree, Self::Leaf)),
            },
        };
        let _ = mem::replace(self, new_self);
        val
    }

    pub fn rebalance(&mut self) {
        let old_self = mem::replace(self, Self::Leaf);
        let new_self = match old_self {
            Self::Leaf => Self::Leaf,
            Self::Node(v, mut l, mut r) => {
                let l_len = l.len();
                let r_len = r.len();
                if l_len >= r_len + 2 {
                    let l_largest = l.largest().remove().unwrap();
                    Self::Node(
                        l_largest,
                        l,
                        Box::new(Self::Node(v, Box::new(Self::Leaf), r)),
                    )
                } else if r_len >= l_len + 2 {
                    let r_smallest = r.smallest().remove().unwrap();
                    Self::Node(
                        r_smallest,
                        Box::new(Self::Node(v, l, Box::new(Self::Leaf))),
                        r,
                    )
                } else {
                    Self::Node(v, l, r)
                }
            }
        };
        let _ = mem::replace(self, new_self);
    }

    // Adapted from https://github.com/bpressure/ascii_tree
    fn fmt_levels(&self, f: &mut fmt::Formatter<'_>, level: Vec<usize>) -> fmt::Result {
        use BinaryTree::*;
        const EMPTY: &str = "   ";
        const EDGE: &str = " └─";
        const PIPE: &str = " │ ";
        const BRANCH: &str = " ├─";

        let maxpos = level.len();
        let mut second_line = String::new();
        for (pos, l) in level.iter().enumerate() {
            let last_row = pos == maxpos - 1;
            if *l == 1 {
                if !last_row {
                    write!(f, "{}", EMPTY)?
                } else {
                    write!(f, "{}", EDGE)?
                }
                second_line.push_str(EMPTY);
            } else {
                if !last_row {
                    write!(f, "{}", PIPE)?
                } else {
                    write!(f, "{}", BRANCH)?
                }
                second_line.push_str(PIPE);
            }
        }

        match self {
            Node(s, l, r) => {
                let mut d = 2;
                write!(f, " {}\n", s)?;
                for t in &[l, r] {
                    let mut lnext = level.clone();
                    lnext.push(d);
                    d -= 1;
                    t.fmt_levels(f, lnext)?;
                }
            }
            Leaf => write!(f, "\n")?,
        }
        Ok(())
    }
}

impl<T: Debug + Display + PartialOrd> fmt::Debug for BinaryTree<T> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        self.fmt_levels(f, vec![])
    }
}

#[cfg(test)]
mod test {
    use super::BinaryTree::*;
    use crate::BinaryTree;
    use lazy_static::lazy_static;

    lazy_static! {
        static ref TEST_TREE: BinaryTree<&'static str> = {
            Node(
                "B",
                Box::new(Node("A", Box::new(Leaf), Box::new(Leaf))),
                Box::new(Node("C", Box::new(Leaf), Box::new(Leaf))),
            )
        };
    }

    #[test]
    fn len_test() {
        assert_eq!(TEST_TREE.len(), 3);
    }

    #[test]
    fn to_vec_test() {
        assert_eq!(TEST_TREE.to_vec(), vec![&"A", &"B", &"C"]);
    }

    #[test]
    fn sorted_test() {
        let mut t = TEST_TREE.clone();
        assert!(t.sorted());

        t = Node("D", Box::new(Leaf), Box::new(t));
        assert!(!t.sorted());
    }

    #[test]
    fn insertion_test() {
        let mut t = TEST_TREE.clone();
        t.insert("E");
        t.insert("A");
        assert!(t.sorted());
    }

    #[test]
    fn search_test() {
        let mut t = TEST_TREE.clone();
        t.insert("E");
        assert!(t.search(&"A") == Some(&"A"));
        assert!(t.search(&"D") == Some(&"E"));
        assert!(t.search(&"C") == Some(&"C"));
        assert!(t.search(&"F") == None);
    }

    #[test]
    fn rebalance1_test() {
        let mut t = Node(
            "D",
            Box::new(Node(
                "B",
                Box::new(Node("A", Box::new(Leaf), Box::new(Leaf))),
                Box::new(Node("C", Box::new(Leaf), Box::new(Leaf))),
            )),
            Box::new(Node("E", Box::new(Leaf), Box::new(Leaf))),
        );

        let t2 = Node(
            "C",
            Box::new(Node(
                "B",
                Box::new(Node("A", Box::new(Leaf), Box::new(Leaf))),
                Box::new(Leaf),
            )),
            Box::new(Node(
                "D",
                Box::new(Leaf),
                Box::new(Node("E", Box::new(Leaf), Box::new(Leaf))),
            )),
        );

        t.rebalance();
        assert_eq!(t, t2);
    }

    #[test]
    fn rebalance2_test() {
        let mut t = Node(
            "A",
            Box::new(Leaf),
            Box::new(Node(
                "B",
                Box::new(Leaf),
                Box::new(Node(
                    "C",
                    Box::new(Leaf),
                    Box::new(Node("D", Box::new(Leaf), Box::new(Leaf))),
                )),
            )),
        );

        let t2 = Node(
            "B",
            Box::new(Node("A", Box::new(Leaf), Box::new(Leaf))),
            Box::new(Node(
                "C",
                Box::new(Leaf),
                Box::new(Node("D", Box::new(Leaf), Box::new(Leaf))),
            )),
        );

        t.rebalance();
        assert_eq!(t, t2);
    }

    #[test]
    fn rebalance2_test_long() {
        let mut t = Node(
            "A",
            Box::new(Leaf),
            Box::new(Node(
                "B",
                Box::new(Leaf),
                Box::new(Node(
                    "C",
                    Box::new(Leaf),
                    Box::new(Node(
                        "D",
                        Box::new(Leaf),
                        Box::new(Node(
                            "E",
                            Box::new(Leaf),
                            Box::new(Node("F", Box::new(Leaf), Box::new(Leaf))),
                        )),
                    )),
                )),
            )),
        );

        let t2 = Node(
            "B",
            Box::new(Node("A", Box::new(Leaf), Box::new(Leaf))),
            Box::new(Node(
                "C",
                Box::new(Leaf),
                Box::new(Node(
                    "D",
                    Box::new(Leaf),
                    Box::new(Node(
                        "E",
                        Box::new(Leaf),
                        Box::new(Node("F", Box::new(Leaf), Box::new(Leaf))),
                    )),
                )),
            )),
        );

        t.rebalance();
        assert_eq!(t, t2);
    }

    #[test]
    fn rebalance3_test() {
        let mut t = Node(
            "E",
            Box::new(Node(
                "B",
                Box::new(Leaf),
                Box::new(Node(
                    "D",
                    Box::new(Node("C", Box::new(Leaf), Box::new(Leaf))),
                    Box::new(Leaf),
                )),
            )),
            Box::new(Node("F", Box::new(Leaf), Box::new(Leaf))),
        );

        let t2 = Node(
            "D",
            Box::new(Node(
                "B",
                Box::new(Leaf),
                Box::new(Node("C", Box::new(Leaf), Box::new(Leaf))),
            )),
            Box::new(Node(
                "E",
                Box::new(Leaf),
                Box::new(Node("F", Box::new(Leaf), Box::new(Leaf))),
            )),
        );

        t.rebalance();
        assert_eq!(t, t2);
    }

    #[test]
    fn rebalance_dummy_test() {
        let mut t = Node("E", Box::new(Leaf), Box::new(Leaf));

        let t2 = Node("E", Box::new(Leaf), Box::new(Leaf));

        t.rebalance();
        assert_eq!(t, t2);

        let mut t1: BinaryTree<u32> = Leaf;
        let t2 = Leaf;

        t1.rebalance();
        assert_eq!(t1, t2);
    }
}
