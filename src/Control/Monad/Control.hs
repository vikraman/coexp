{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE TypeOperators #-}

module Control.Monad.Control
  ( type (+),
    type (-),
    type (#),
    type (~>),
    MonadControl (..),
    lem,
    callCC,
    throw,
  )
where

infixr 5 +

type a + b = Either a b

infix 7 #

type a # k = k a

infixr 5 -

type (b - a) k = (b, a # k)

infixr 3 ~>

type (a ~> b) m = a -> m b

class (Monad m) => MonadControl m k where
  colam :: ((a # k ~> b) m ~> (b + a)) m
  coapp :: ((b + a, a # k) ~> b) m

  cocurry :: (c ~> b + a) m -> ((c - a) k ~> b) m
  cocurry f (c, k) = f c >>= coapp . (,k)

  councurry :: ((c - a) k ~> b) m -> (c ~> b + a) m
  councurry f c = colam (f . (c,))

  coeval :: (b ~> (b - a) k + a) m
  coeval = councurry pure

  couneval :: (((b + a) - a) k ~> b) m
  couneval = cocurry pure

lem :: (MonadControl m k) => (() ~> a # k + a) m
lem () = colam pure

codiag :: a + a -> a
codiag = either id id

callCC :: (MonadControl m k) => ((a # k ~> a) m ~> a) m
callCC = fmap codiag . colam

throw :: (MonadControl m k) => ((a, a # k) ~> b) m
throw (a, k) = coapp (Right a, k)
