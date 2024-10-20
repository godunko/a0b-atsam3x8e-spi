--
--  Copyright (C) 2024, Vadim Godunko
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with A0B.ATSAM3X8E.PIO;

generic
   MISO : in out A0B.ATSAM3X8E.PIO.SPI0_MISO_Line'Class;
   MOSI : in out A0B.ATSAM3X8E.PIO.SPI0_MOSI_Line'Class;
   SPCK : in out A0B.ATSAM3X8E.PIO.SPI0_SPCK_Line'Class;

package A0B.ATSAM3X8E.SPI.Generic_SPI0
  with Preelaborate
is

   type SPI0_Controller is new SPI_Bus
          (Peripheral => A0B.ATSAM3X8E.SVD.SPI.SPI0_Periph'Access,
           Identifier => Serial_Peripheral_Interface_0) with null record
       with Preelaborable_Initialization;

   procedure Initialize (Self : in out SPI0_Controller'Class);

   procedure Configure_Master (Self : in out SPI0_Controller'Class);

   SPI0 : aliased SPI0_Controller;

end A0B.ATSAM3X8E.SPI.Generic_SPI0;
