(module
  ;; Define memory named $memory and export
  (memory $memory 1)  ;; First memory declared is default, with index 0
  (export "memory" (memory $memory))

  (func $mystery (param $n i32) (result i32)
    ;; movl $0, -4(%rsp)
    ;; we store it to address 0
    (i32.const 0)
    (i32.const 0)
    (i32.store)

    (block $end_while
      (loop $while
        ;; addl $1, -4(%rsp)
        (i32.const 0) ;; <- this address is used at the end
                      ;;    when storing value back to memory
        (i32.const 0) ;;    |
        (i32.load)    ;;    |
        (i32.const 1) ;;    |
        (i32.add)     ;;    |
                      ;;    |
        (i32.store)   ;; <--+

        ;; cmpl $1, %edi
        ;; je	ENDWHILE
        (get_local 0)
        (i32.const 1)
        (i32.eq)
        (br_if $end_while)

        (block $end_if
          (block $else
            ;; calculate %edi mod 2
            (get_local 0)
            (i32.const 2)
            (i32.rem_s)
            ;; if the value != 0 then go to ELSE
            (i32.const 0)
            (i32.ne)
            (br_if $else)
            ;; THEN:
            ;; %edi = %edi / 2
            (get_local 0)
            (i32.const 2)
            (i32.div_s)
            (set_local 0)

            (br $end_if)
          )
          ;; ELSE:
          ;; %edi = %edi * 3 + 1
          (get_local 0)
          (i32.const 3)
          (i32.mul)
          (i32.const 1)
          (i32.add)
          (set_local 0)

          (br $end_if)
        )
        ;; ENDIF:
        (br $while)
      )
    )
    ;; ENDWHILE:
    ;; movl -4(%rsp), %eax
    ;; retq
    (i32.const 0)
    (i32.load)

    )
  (export "mystery" (func $mystery))
  )
