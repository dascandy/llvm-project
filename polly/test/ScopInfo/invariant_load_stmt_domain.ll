; RUN: opt %loadNPMPolly '-passes=print<polly-function-scops>' -polly-invariant-load-hoisting=true -disable-output < %s 2>&1 | FileCheck %s

; This test case verifies that the statement domain of the invariant access
; is the universe. In earlier versions of Polly, we accidentally computed an
; empty access domain which resulted in invariant accesses not being executed
; and consequently undef values being used.

; CHECK:  Invariant Accesses: {
; CHECK-NEXT:          ReadAccess :=       [Reduction Type: NONE] [Scalar: 0]
; CHECK-NEXT:              { Stmt_loop_next[i0] -> MemRef_a[1] };
; CHECK-NEXT:          Execution Context: {  :  }
; CHECK-NEXT:  }
; CHECK-NEXT:  Context:
; CHECK-NEXT:  {  :  }
; CHECK-NEXT:  Assumed Context:
; CHECK-NEXT:  {  :  }
; CHECK-NEXT:  Invalid Context:
; CHECK-NEXT:  {  : false }

; CHECK:  Statements {
; CHECK-NEXT:    Stmt_loop
; CHECK-NEXT:          Domain :=
; CHECK-NEXT:              { Stmt_loop[i0] : 0 <= i0 <= 1 };
; CHECK-NEXT:          Schedule :=
; CHECK-NEXT:              { Stmt_loop[i0] -> [i0, 0] };
; CHECK-NEXT:          ReadAccess :=       [Reduction Type: NONE] [Scalar: 1]
; CHECK-NEXT:              { Stmt_loop[i0] -> MemRef_val__phi[] };
; CHECK-NEXT:          MustWriteAccess :=  [Reduction Type: NONE] [Scalar: 0]
; CHECK-NEXT:              { Stmt_loop[i0] -> MemRef_B[i0] };
; CHECK-NEXT:    Stmt_loop_next
; CHECK-NEXT:          Domain :=
; CHECK-NEXT:              { Stmt_loop_next[0] };
; CHECK-NEXT:          Schedule :=
; CHECK-NEXT:              { Stmt_loop_next[i0] -> [0, 1] };
; CHECK-NEXT:          MustWriteAccess :=  [Reduction Type: NONE] [Scalar: 1]
; CHECK-NEXT:              { Stmt_loop_next[i0] -> MemRef_val__phi[] };
; CHECK-NEXT:  }

define void @foo(ptr %a, ptr noalias %B) {
entry:
  br label %loop

loop:
  %indvar = phi i64 [0, %entry], [%indvar.next, %loop.next]
  %val = phi float [1.0, %entry], [%a.val, %loop.next]
  %indvar.next = add nuw nsw i64 %indvar, 1
  %ptr = getelementptr float, ptr %B, i64 %indvar
  store float %val, ptr %ptr
  %icmp = icmp eq i64 %indvar.next, 2
  br i1 %icmp, label %ret, label %loop.next

loop.next:
  %Aptr = getelementptr float, ptr %a, i64 %indvar.next
  %a.val = load float, ptr %Aptr
  br label %loop

ret:
  ret void
}
