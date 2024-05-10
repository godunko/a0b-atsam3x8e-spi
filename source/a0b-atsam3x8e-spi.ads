--
--  Copyright (C) 2024, Vadim Godunko
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with System;

with A0B.ATSAM3X8E.PIO;
private with A0B.Callbacks;
with A0B.SPI;
with A0B.SVD.ATSAM3X8E.SPI;
private with A0B.Types;

package A0B.ATSAM3X8E.SPI
  with Preelaborate
is

   type SPI_Slave_Device is tagged;

   type SPI_Bus
     (Peripheral : not null access A0B.SVD.ATSAM3X8E.SPI.SPI0_Peripheral;
      Identifier : Peripheral_Identifier)
   --    is abstract limited new A0B.SPI.SPI_Bus with
     is abstract tagged limited
   record
      Selected_Device : access SPI_Slave_Device'Class;
   end record;

   type SPI_Slave_Device
     (Bus  : not null access SPI_Bus'Class;
      NPCS : not null access A0B.ATSAM3X8E.PIO.ATSAM3X8E_Pin'Class) is
     limited new A0B.SPI.SPI_Slave_Device with private;

   procedure Configure (Self : in out SPI_Slave_Device'Class);

   procedure Select_Device (Self : in out SPI_Slave_Device'Class);

   procedure Release_Device (Self : in out SPI_Slave_Device'Class);

   --  procedure Initialize;

private

   type SPI_Slave_Device
     (Bus  : not null access SPI_Bus'Class;
      NPCS : not null access A0B.ATSAM3X8E.PIO.ATSAM3X8E_Pin'Class) is
     limited new A0B.SPI.SPI_Slave_Device with
   record
      Transmit_Buffer   : System.Address;
      Receive_Buffer    : System.Address;
      Finished_Callback : A0B.Callbacks.Callback;
   end record;

   overriding procedure Transfer
     (Self              : in out SPI_Slave_Device;
      Transmit_Buffer   : aliased A0B.Types.Unsigned_8;
      Receive_Buffer    : aliased out A0B.Types.Unsigned_8;
      Finished_Callback : A0B.Callbacks.Callback);

   overriding procedure Transmit
     (Self              : in out SPI_Slave_Device;
      Transmit_Buffer   : aliased A0B.Types.Unsigned_8;
      Finished_Callback : A0B.Callbacks.Callback);

   procedure On_Interrupt (Self : in out SPI_Bus'Class);

end A0B.ATSAM3X8E.SPI;