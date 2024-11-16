(*
 * AutoRun
 *
 * PLATFORMS
 *   Windows
 *
 * LICENSE
 *   Copyright (c) 2021 HOSOKAWA Jun
 *   Released under the MIT license
 *   http://opensource.org/licenses/mit-license.php
 *
 * HISTORY
 *   2017/06/08  Ver 1.0.0  Release
 *
 * Programmed by HOSOKAWA Jun (twitter: @pik)
 *)

unit PK.AutoRun.Types;

interface

type
  IAutoRun = interface
  ['{54367FB0-89D0-4693-8DDE-4BB4246BDA4A}']
    function Register(const AName: String): Boolean;
    function Unregister(const AName: String): Boolean;
    function GetRegistered(const AName: String): Boolean;
  end;

  IAutoRunFactory = interface
  ['{50C0FF7C-5860-4E14-B7E3-C047D191B419}']
    function CreateAutoRun: IAutoRun;
  end;

  TAutoRunFactory = class(TInterfacedObject, IAutoRunFactory)
  public
    function CreateAutoRun: IAutoRun; virtual; abstract;
  end;

implementation

end.
