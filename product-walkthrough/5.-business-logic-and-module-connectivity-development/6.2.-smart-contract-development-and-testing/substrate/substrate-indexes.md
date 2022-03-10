---
description: Common data structures for storing data on-chain.
---

# Copy of Data Structures

A totally ordered multiset is a multiset + a relation on the set that satisfies the conditions for a partial order + an additional condition known as the comparability condition. This data structure has a variety of helpful operators for iterating.

## Functions

`storage-tomulset-index` constructs a multiset whose elements are totally ordered sets (by insertion order). It allows paginated retrieval of elements in a named set.

`storage-toset-next-iters` constructs an iterator across a set of tosets with arguments: whether to forward iterate, bookmark, first toset, and \&rest of other tosets. Takes the following operations.

`'enumerate` returns a vector of 2 elements: a list of items and an empty bookmark. This can also take a filter.

```
shiro> (let* ([tms1 (storage-tomulset-index "test1")]
              [tms2 (storage-tomulset-index "test2")])
         (tms1 'put "A" 1)
         (tms1 'put "A" 2)
         (tms2 'put "B" 3)
         (tms2 'put "B" 4)
         (let* ([ts1 (tms1 'get-set "A")]
                [ts2 (tms2 'get-set "B")]
                [iters (storage-toset-next-iters true () ts1 ts2)])
           (iters 'enumerate)))
(vector (vector 1 2 3 4) (vector))

shiro> (let* ([tms1 (storage-tomulset-index "test1")]
              [tms2 (storage-tomulset-index "test2")])
         (tms1 'put "A" 1)
         (tms1 'put "A" 2)
         (tms2 'put "B" 3)
         (tms2 'put "B" 4)
         (let* ([ts1 (tms1 'get-set "A")]
                [ts2 (tms2 'get-set "B")]
                [iters (storage-toset-next-iters false () ts1 ts2)])
           (iters 'enumerate)))
(vector (vector 2 1 4 3) (vector))

shiro> (let* ([tms1 (storage-tomulset-index "test1")]
              [tms2 (storage-tomulset-index "test2")])
         (tms1 'put "A" 1)
         (tms1 'put "A" 2)
         (tms2 'put "B" 3)
         (tms2 'put "B" 4)
         (let* ([ts1 (tms1 'get-set "A")]
                [ts2 (tms2 'get-set "B")]
                [iters (storage-toset-next-iters true () ts1 ts2)])
           (iters 'enumerate (lambda (e) (= 1 e))))) # added filter
(vector (vector 1) "MTo=")

shiro> (let* ([tms1 (storage-tomulset-index "test1")]
              [tms2 (storage-tomulset-index "test2")])
         (tms1 'put "A" 1)
         (tms1 'put "A" 2)
         (tms2 'put "B" 3)
         (tms2 'put "B" 4)
         (let* ([ts1 (tms1 'get-set "A")]
                [ts2 (tms2 'get-set "B")]
                [iters (storage-toset-next-iters true "MTo=" ts1 ts2)])
           (iters 'enumerate (lambda (e) (= 1 e)))))
(vector (vector) "MTo=")
```

`'page` takes a page size + filter and returns a vector of 2 elements: a list of items and a bookmark of the last item accessed. To access the next group of items, provide the bookmark to the `storage-toset-next-iters` function.

```
shiro> (let* ([tms1 (storage-tomulset-index "test1")]
              [tms2 (storage-tomulset-index "test2")])
         (tms1 'put "A" 1)
         (tms1 'put "A" 2)
         (tms2 'put "B" 3)
         (tms2 'put "B" 4)
         (let* ([ts1 (tms1 'get-set "A")]
                [ts2 (tms2 'get-set "B")]
                [iters (storage-toset-next-iters true () ts1 ts2)])
           (iters 'page 2 (lambda (e) true))))
(vector (vector 1 2) "Xzo=")

shiro> (let* ([tms1 (storage-tomulset-index "test1")]
              [tms2 (storage-tomulset-index "test2")])
         (tms1 'put "A" 1)
         (tms1 'put "A" 2)
         (tms2 'put "B" 3)
         (tms2 'put "B" 4)
         (let* ([ts1 (tms1 'get-set "A")]
                [ts2 (tms2 'get-set "B")]
                [iters (storage-toset-next-iters true "Xzo=" ts1 ts2)]) # added bookmark
           (iters 'page 2 (lambda (e) true))))
(vector (vector 3 4) (vector))
```

#### B+ trees

B+ trees are available for optimizing data storage. Storing key/value pairs in a B+ trees on the ledger is beneficial for two reasons. Firstly, loading multiple keys may be more efficient if locality of reference exists -- there is the possibility that a B+ tree may only need to load one leaf node to satisfy a number of sequential reads in the same node. Secondly, when a B+ tree is backed by a private data collection (PDC), it can support range queries where the PDC itself cannot. Naturally, B+ trees are not appropriate to all use cases. Some use cases may see decreased performance if B+ trees cause excessive unnecessary I/O, or additional MVCC conflicts due to false sharing.&#x20;

Prior to the existence of the B+ tree implementation, the platform had supported tomulsets. After the addition of B+ trees, a compatibility layer was added that allows clients using the tomulset API to switch to B+ tree backing (a data migration may also be necessary). Each tomulset is emulated using two B+ trees, called \`ixo\` and \`eat\`.&#x20;

\`storage-tomulset-index\` takes a keyword parameter called \`factory-toset-index\`. An argument can be supplied that is the result of invoking \`storage-toset-index-bptree-factory\`. The latter function takes optional parameters \`ixo-hdk\`, \`ixo-hdv\`, \`eat-hdk\`, and \`eat-hdv\`. Each of the two B+ trees, \`ixo\` and \`eat\` takes \`hdk\` and \`hdv\` parameters. \`hdk\` specifies the number of keys in interior nodes. \`hdv\` specifies the number of key/value pairs in leaf nodes. B+ trees have no values in interior nodes.&#x20;

Performance tuning: Setting \`hdk\` lower will limit the branching factor of the tree and increase its depth, requiring more lookups to localize a particular key. Setting \`hdk\` higher may cause delays related to the I/O required to load the large nodes from the ledger, and to search for keys within the interior node (which is still done by linear scan currently). The same consideration applies to setting \`hdv\` higher. Setting \`hdv\` lower will increase the number of nodes in the tree.

The choice of parameter doesn't depend much on the query size. The choice of parameters depends more on the average (or better yet, distribution) of the key length and value length as well as the access pattern. The goal is for interior nodes (which have only keys) as well as leaf nodes (which have keys and values) to generally fit into a chosen I/O size that strikes a balance between providing a high throughput on the one hand and not exceeding the diminishing returns of locality of reference on the other. So, in summary, the choice of parameter depends on the key and value sizes so it's best to try a few different values empirically with real-world data, benchmark them with a realistic or real-word access pattern, and choose the best results.

```
(use-package 'cc-bptree)
(use-package 'testing)

(defun stringify (pairs)
  (string:join
   (map 'list
        (lambda (pair)
          (string:join (list (first pair) (to-string (second pair))) ","))
        pairs)
   ";"))

(defun bptree-enumerate (handle)
  (bptree-range-limit-query handle true 1000000000 '() '()))

(test "open/insert/query/delete"
      (let* ([handle (bptree-open "private" "mybptree" '() 2 2 false false)])
        (assert (nil? (bptree-insert handle "k2" (to-bytes "v2"))))
        (assert (nil? (bptree-insert handle "k1" (to-bytes "v1"))))
        (assert (nil? (bptree-insert handle "k3" (to-bytes "v3"))))
        (assert-equal "k1,v1;k2,v2;k3,v3" (stringify (bptree-enumerate handle)))
        (assert (nil? (bptree-delete handle "k2")))
        (assert-equal "k1,v1;k3,v3" (stringify (bptree-enumerate handle)))))

(test "coherency"
      (let* ([handleA (bptree-open "" "mybptree2" '() 2 2 false false)]
             [handleB (bptree-open "" "mybptree2" '() 2 2 false false)])
        (assert (nil? (bptree-insert handleA "k1" (to-bytes "v1"))))
        (assert (nil? (bptree-flush-dirty handleA)))
        (assert-equal "k1,v1" (stringify (bptree-enumerate handleB)))))

(test "coherency2"
      (let* ([handleA (bptree-open "" "mybptree2" '() 2 2 false false)]
             [handleB (bptree-open "" "mybptree2" '() 2 2 false false)])
        (assert (nil? (bptree-insert handleA "k1" (to-bytes "v1"))))
        (assert-equal "" (stringify (bptree-enumerate handleB)))))

(test "coherency3"
      (let* ([handleA (bptree-open "" "mybptree2" '() 2 2 true false)]
             [handleB (bptree-open "" "mybptree2" '() 2 2 false false)])
        (assert (nil? (bptree-insert handleA "k1" (to-bytes "v1"))))
        (assert-equal "k1,v1" (stringify (bptree-enumerate handleB)))))

(defun compare (a b)
  (cond ((string< a b)  1)
        ((string> a b) -1)
        (:else 0)))

(test "comparison"
      (let* ([handle (bptree-open "private" "mybptree" compare 2 2 false false)])
        (assert (nil? (bptree-insert handle "k2" (to-bytes "v2"))))
        (assert (nil? (bptree-insert handle "k1" (to-bytes "v1"))))
        (assert (nil? (bptree-insert handle "k3" (to-bytes "v3"))))
        (assert-equal "k3,v3;k2,v2;k1,v1" (stringify (bptree-enumerate handle)))
        (assert (nil? (bptree-delete handle "k2")))
        (assert-equal "k3,v3;k1,v1" (stringify (bptree-enumerate handle)))))

(test "deletion"
      (let* ([handle (bptree-open "" "mybptree" '() 2 2 true false)])
        (assert (nil? (bptree-insert handle "k2" (to-bytes "v2"))))
        (assert (nil? (bptree-insert handle "k1" (to-bytes "v1"))))
        (assert (nil? (bptree-insert handle "k3" (to-bytes "v3"))))
        (assert (nil? (bptree-delete-tree handle)))
        (let* ([handle (bptree-open "" "mybptree" '() 2 2 true false)])
          (assert-equal "" (stringify (bptree-enumerate handle))))))

(test "open/insert/rank/query/delete"
      (let* ([handle (bptree-open "private" "mybptree" '() 2 2 false true)])
        (assert (nil? (bptree-insert handle "k2" (to-bytes "v2"))))
        (assert (nil? (bptree-insert handle "k1" (to-bytes "v1"))))
        (assert (nil? (bptree-insert handle "k3" (to-bytes "v3"))))
        (assert-equal 0 (bptree-rank-query handle "k1"))
        (assert-equal 1 (bptree-rank-query handle "k11"))
        (assert-equal 1 (bptree-rank-query handle "k2"))
        (assert-equal 2 (bptree-rank-query handle "k21"))
        (assert-equal 2 (bptree-rank-query handle "k3"))
        (assert-equal 3 (bptree-rank-query handle "k31"))
        (assert-equal 3 (bptree-rank-query handle '()))
        (assert-equal "k1,v1;k2,v2;k3,v3" (stringify (bptree-enumerate handle)))
        (assert (nil? (bptree-delete handle "k2")))
        (assert-equal "k1,v1;k3,v3" (stringify (bptree-enumerate handle)))))
```

```
(defun test-storage-tomulset-index (name &optional store factory-toset-index)
  (let* ([idx (storage-tomulset-index name :store store :factory-toset-index factory-toset-index)])
    (assert (not (idx 'has? "a" 1)))
    (idx 'put "a" 1)
    (assert (idx 'has? "a" 1))
    (idx 'put "a" 2)
    (let* ([got (idx 'page "a" (lambda (x) true) () 3)]
           [res (first got)]
           [bmk (second got)])
      (assert-deep-equal (vector 1 2) res)
      (assert-equal () bmk))
    ))
(test "storage-tomulset-index-statedb" (test-storage-tomulset-index "storage-tomulset-index-statedb"))
(test "storage-tomulset-index-statedb-bptree" (test-storage-tomulset-index "storage-tomulset-index-statedb-bptree" '() (storage-toset-index-bptree-factory 50 10 50 10)))
```

```
(export 'storage-toset-index-bptree-factory)
(defun storage-toset-index-bptree-factory (&optional ixo-hdk ixo-hdv eat-hdk eat-hdv))
```

## Operations

`'put` inserts a given item into the tomulset of a provided key.

```
shiro> (let* ([tms (storage-tomulset-index "test")])
         (tms 'put "A" 1)
         (tms 'put "A" 2)
         (tms 'enumerate "A"))
(vector 1 2)
```

`'del` deletes a given element from a provided key.

```
shiro> (let* ([tms (storage-tomulset-index "test")])
         (tms 'put "A" 1)
         (tms 'put "A" 2)
         (tms 'del "A" 2)
         (tms 'enumerate "A"))
(vector 1)
```

`'has?` returns true if a provided key is in the tomulset, false otherwise.

```
shiro> (let* ([tms (storage-tomulset-index "test")])
         (tms 'put "A" 1)
         (tms 'put "A" 2)
         (tms 'has? "A" 1))
true

shiro> (let* ([tms (storage-tomulset-index "test")])
         (tms 'put "A" 1)
         (tms 'put "A" 2)
         (tms 'has? "A" 3))
false
```

`'count` returns the number of items of a provided key.

```
shiro> (let* ([tms (storage-tomulset-index "test")])
         (tms 'put "A" 1)
         (tms 'put "A" 2)
         (tms 'count "A"))
2
```

`'page` pages forward the tomulset with a given filter, bookmark, and page size.

```
shiro> (let* ([tms (storage-tomulset-index "test")])
         (tms 'put "X" "X1")
         (tms 'put "X" "X2")
         (tms 'page "X" (lambda (e) true) () 1))
'((vector "X1") "1")
shiro> 
shiro> 
shiro> (let* ([tms (storage-tomulset-index "test")])
         (tms 'put "X" "X1")
         (tms 'put "X" "X2")
         (tms 'page "X" (lambda (e) true) 1 1)) # added bookmark
'((vector "X2") ())
```

`'page-back` pages backward the tomulset with a given filter, bookmark, and page size.

```
shiro> (let* ([tms (storage-tomulset-index "test")])
         (tms 'put "X" "X1")
         (tms 'put "X" "X2")
         (tms 'page-back "X" (lambda (e) true) () 1))
'((vector "X2") "2")
shiro> 
shiro> 
shiro> (let* ([tms (storage-tomulset-index "test")])
         (tms 'put "X" "X1")
         (tms 'put "X" "X2")
         (tms 'page-back "X" (lambda (e) true) 2 1)) #added bookmark
'((vector "X1") ())
```

`'enumerate` returns the entire list of items of a provided tomulset ket.

```
shiro> (let* ([tms (storage-tomulset-index "test")])
         (tms 'put "A" 1)
         (tms 'put "A" 2)
         (tms 'enumerate "A"))
(vector 1 2)
```

`'dump` evaluates to the DB key/value pairs that define the tomulset contents.

```
shiro> (let* ([tms (storage-tomulset-index "test")])
         (tms 'put "X" "X1")
         (tms 'put "X" "X2")
         (tms 'dump "X"))
(sorted-map "acr:bimap:test-X-ctr:a:1" "X1" "acr:bimap:test-X-ctr:a:2" "X2" "acr:bimap:test-X-ctr:b:X1" 1 "acr:bimap:test-X-ctr:b:X2" 2 "acr:ctr:test-X-len" 2 "acr:ctr:test-X-max" 2 "acr:ctr:test-X-min" 1 "acr:page:test-X:1" "5EF284AD" "acr:page:test-X:2" "5EF284AD")
```

`'free` deletes the entire tomulset for the given key.

```
shiro> (let* ([tms (storage-tomulset-index "test")])
         (tms 'put "A" 1)
         (tms 'put "A" 2)
         (tms 'free "A")
         (tms 'enumerate "A"))
(vector)
```

`'next-iter` creates an iterator for the given key, can be used with `'page` and `'enumerate`.

```
shiro> (let* ([tms (storage-tomulset-index "test")])
         (tms 'put "X" "X1")
         (tms 'put "X" "X2")
         ((tms 'next-iter "X") 'enumerate))
(vector (vector "X1" "X2") (vector))
```

`'prev-iter` creates an iterator that goes backwards for the given key, can be used with `'page` and `'enumerate`.

```
shiro> (let* ([tms (storage-tomulset-index "test")])
         (tms 'put "X" "X1")
         (tms 'put "X" "X2")
         ((tms 'prev-iter "X") 'enumerate))
(vector (vector "X2" "X1") (vector))
```

`'get-set` makes a toset provided a key to the tomulset.

```
shiro> (let* ([tms (storage-tomulset-index "test")])
         (tms 'put "A" 1)
         (tms 'put "A" 2)
         (let* ([ts (tms 'get-set "A")])
           (ts 'enumerate)))
(vector 1 2)
```
