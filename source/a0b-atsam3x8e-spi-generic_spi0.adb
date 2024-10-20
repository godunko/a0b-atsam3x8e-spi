--
--  Copyright (C) 2024, Vadim Godunko
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

pragma Ada_2022;

with A0B.ATSAM3X8E.SVD.PMC; use A0B.ATSAM3X8E.SVD.PMC;

package body A0B.ATSAM3X8E.SPI.Generic_SPI0 is

   pragma Warnings
     (Off,
      "all instances of ""SPI0_Handler"" will have the same external name");

   procedure SPI0_Handler
     with Export, Convention => C, External_Name => "SPI0_Handler";

   ----------------------
   -- Configure_Master --
   ----------------------

   procedure Configure_Master (Self : in out SPI0_Controller'Class) is
   begin
      SPI_Bus (Self).Peripheral.MR :=
        (MSTR    => True,   --  SPI is in Master mode.
         PS      => False,  --  Fixed Peripheral Select.
         PCSDEC  => False,
         --  The chip selects are directly connected to a peripheral device.
         MODFDIS => True,   --  Mode fault detection is disabled.
         WDRBT   => False,
         --  No Effect. In master mode, a transfer can be initiated whatever
         --  the state of the Receive Data Register is.
         LLB     => False,  --  Local loopback path disabled.
         PCS     => 2#1110#,
         DLYBCS  => 0,
         others  => <>);

      MISO.Configure_SPI_MISO (Pullup => True);
      MOSI.Configure_SPI_MOSI (Pullup => True);
      SPCK.Configure_SPI_SPCK (Pullup => True);
   end Configure_Master;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Self : in out SPI0_Controller'Class) is
   begin
      PMC_Periph.PMC_PCER0 :=
        (PID    =>
           (As_Array => True,
            Arr      =>
              [A0B.ATSAM3X8E.Serial_Peripheral_Interface_0 => True,
               others => False]),
         others => <>);

      SPI_Bus (Self).Peripheral.CR :=
        (SPIEN    => False,
         SPIDIS   => True,
         SWRST    => False,
         LASTXFER => False,
         others   => <>);
      --  Disable transmission

      SPI_Bus (Self).Peripheral.CR :=
        (SPIEN    => False,
         SPIDIS   => False,
         SWRST    => True,
         LASTXFER => False,
         others   => <>);
      --  Reset controller
   end Initialize;

   ------------------
   -- SPI0_Handler --
   ------------------

   procedure SPI0_Handler is
   begin
      SPI0.On_Interrupt;
   end SPI0_Handler;

end A0B.ATSAM3X8E.SPI.Generic_SPI0;
