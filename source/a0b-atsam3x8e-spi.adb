--
--  Copyright (C) 2024, Vadim Godunko
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with A0B.ARMv7M.NVIC_Utilities; use A0B.ARMv7M.NVIC_Utilities;
with A0B.SVD.ATSAM3X8E.SPI;     use A0B.SVD.ATSAM3X8E.SPI;

package body A0B.ATSAM3X8E.SPI is

   ---------------
   -- Configure --
   ---------------

   procedure Configure (Self : in out SPI_Slave_Device'Class) is
   begin
      Self.NPCS.Configure_Output (Pullup => True);
      Self.NPCS.Set (True);

      Self.Bus.Peripheral.CSR_0 :=
        (CPOL   => True,
         --  The inactive state value of SPCK is logic level one.
         NCPHA  => False,
         --  Data is changed on the leading edge of SPCK and captured on the
         --  following edge of SPCK.
         CSNAAT => False,      --  Ignored due to CSAAT => True
         CSAAT  => True,
         --  The Peripheral Chip Select does not rise after the last transfer
         --  is achieved. It remains active until a new transfer is requested
         --  on a different chip select.
         BITS   => Val_8_BIT,  --  8 bits for transfer
         --  SCBR   => 255,
         SCBR   => 168,
         DLYBS  => 0,
         --  This field defines the delay from NPCS valid to the first valid
         --  SPCK transition. When DLYBS equals zero, the NPCS valid to SPCK
         --  transition is 1/2 the SPCK clock period.
         DLYBCT => 0);
         --  This field defines the delay between two consecutive transfers
         --  with the same peripheral without removing the chip select. The
         --  delay is always inserted after each transfer and before removing
         --  the chip select if needed. When DLYBCT equals zero, no delay
         --  between consecutive transfers is inserted and the clock keeps
         --  its duty cycle over the character transfers.

      Self.Bus.Peripheral.IER :=
        (RDRF   => True,
         others => <>);
      --  Enable RDRF (Receive Data Register Full) interrupt.
   end Configure;

   ------------------
   -- On_Interrupt --
   ------------------

   procedure On_Interrupt (Self : in out SPI_Bus'Class) is
      use type System.Address;

      Status : constant A0B.SVD.ATSAM3X8E.SPI.SPI0_SR_Register :=
        SPI0_Periph.SR;
      Mask   : constant A0B.SVD.ATSAM3X8E.SPI.SPI0_IMR_Register :=
        SPI0_Periph.IMR;

   begin
      if Status.RDRF and Mask.RDRF then
         if Self.Selected_Device.Receive_Buffer /= System.Null_Address then
            declare
               Data : A0B.Types.Unsigned_8
                 with Import,
                      Convention => Ada,
                      Address    => Self.Selected_Device.Receive_Buffer;

            begin
               Data := A0B.Types.Unsigned_8 (SPI0_Periph.RDR.RD);
            end;

         else
            declare
               Data : A0B.Types.Unsigned_8 with Unreferenced;

            begin
               Data := A0B.Types.Unsigned_8 (SPI0_Periph.RDR.RD);
               --  Read register to clear RDRF interrupt status flag.
            end;
         end if;

         A0B.Callbacks.Emit (Self.Selected_Device.Finished_Callback);

      else
         raise Program_Error;
      end if;
   end On_Interrupt;

   --------------------
   -- Release_Device --
   --------------------

   procedure Release_Device (Self : in out SPI_Slave_Device'Class) is
   begin
      Disable_Interrupt
        (A0B.ARMv7M.External_Interrupt_Number (Self.Bus.Identifier));

      Self.Bus.Peripheral.CR :=
        (SPIEN    => False,
         SPIDIS   => True,
         SWRST    => False,
         LASTXFER => False,
         others   => <>);

      Self.NPCS.Set (True);

      Self.Bus.Selected_Device := null;
   end Release_Device;

   -------------------
   -- Select_Device --
   -------------------

   procedure Select_Device (Self : in out SPI_Slave_Device'Class) is
   begin
      Self.Bus.Selected_Device := Self'Unchecked_Access;

      Self.NPCS.Set (False);

      Self.Bus.Peripheral.CR :=
        (SPIEN    => True,
         SPIDIS   => False,
         SWRST    => False,
         LASTXFER => False,
         others   => <>);

      Clear_Pending
        (A0B.ARMv7M.External_Interrupt_Number (Self.Bus.Identifier));
      Enable_Interrupt
        (A0B.ARMv7M.External_Interrupt_Number (Self.Bus.Identifier));
   end Select_Device;

   --------------
   -- Transfer --
   --------------

   overriding procedure Transfer
     (Self              : in out SPI_Slave_Device;
      Transmit_Buffer   : aliased A0B.Types.Unsigned_8;
      Receive_Buffer    : aliased out A0B.Types.Unsigned_8;
      Finished_Callback : A0B.Callbacks.Callback) is
   begin
      Self.Transmit_Buffer   := Transmit_Buffer'Address;
      Self.Receive_Buffer    := Receive_Buffer'Address;
      Self.Finished_Callback := Finished_Callback;

      declare
         Data : constant A0B.Types.Unsigned_8
           with Import, Convention => Ada, Address => Self.Transmit_Buffer;

      begin
         Self.Bus.Peripheral.TDR :=
           (TD       => SPI0_TDR_TD_Field (Data),
            PCS      => 2#1110#,
            LASTXFER => False,
            others   => <>);
      end;
   end Transfer;

   --------------
   -- Transmit --
   --------------

   overriding procedure Transmit
     (Self              : in out SPI_Slave_Device;
      Transmit_Buffer   : aliased A0B.Types.Unsigned_8;
      Finished_Callback : A0B.Callbacks.Callback) is
   begin
      Self.Transmit_Buffer   := Transmit_Buffer'Address;
      Self.Receive_Buffer    := System.Null_Address;
      Self.Finished_Callback := Finished_Callback;

      declare
         Data : constant A0B.Types.Unsigned_8
           with Import, Convention => Ada, Address => Self.Transmit_Buffer;

      begin
         Self.Bus.Peripheral.TDR :=
           (TD       => SPI0_TDR_TD_Field (Data),
            PCS      => 2#1110#,
            LASTXFER => False,
            others   => <>);
      end;
   end Transmit;

end A0B.ATSAM3X8E.SPI;