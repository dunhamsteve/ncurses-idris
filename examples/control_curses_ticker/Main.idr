module Main

import System
import System.Signal
import Control.NCurses
import Control.NCurses.Pretty
import Data.Nat

instructions : String
instructions = "Ctrl+C to quit. Up/Down arrows to adjust ticker.\n"

displayTicker : IsActive s => InWindow "ticker" s => HasColor "green" s => HasColor "white" s => Nat -> NCurses () s (const s)
displayTicker k =
  let mid = (cast $ length instructions) `div` 2
      centered = mid - ((cast $ (length (show k)) + 4) `div` 2)
  in
  printDoc $ indent centered $
    hsep [ dash
         , color "green" (bold $ pretty k)
         , dash
         ]
  where
    dash : Doc (Attribute s)
    dash = color "white" $ pretty "-"

loop : IsActive s => InWindow "ticker" s => HasColor "green" s => HasColor "white" s => YesDelay s => YesKeypad s => Nat -> NCurses () s (const s)
loop n = do
  keyOrCh <- getKeyOrChar
  tally keyOrCh
    where
      loopOrExit : Nat -> NCurses () s (const s)
      loopOrExit n' = 
        case !(liftIO handleNextCollectedSignal) of
             (Just SigINT) => pure ()
             _ => loop n'

      tally : Either Char Key -> NCurses () s (const s)
      tally x = do
        erase
        let n' = case x of Right Up => (pred n); Right Down => (S n); _ => n
        displayTicker n'
        refresh
        loopOrExit n'

run : NCurses () Inactive (const Inactive)
run = TransitionIndexed.Do.do
  init
  (MkSize rows cols) <- getSize
  let centerX = (cols `div` 2) `minus` ((length instructions) `div` 2)
  let centerY = (rows `div` 2)
  addColor "green" Green Black
  addColor "white" White Black
  setCursor CInvisible
  addWindow "header" (MkPosition centerY     centerX) (MkSize 1 (length instructions))
  addWindow "ticker" (MkPosition (S centerY) centerX) (MkSize 1 (length instructions))
  clear
  setWindow "header"
  putStrLn instructions
  refresh
  setWindow "ticker"
  let n = 25
  displayTicker n
  loop n
  deinit

main : IO ()
main = do
  ignore $ collectSignal SigINT
  withNCurses run

