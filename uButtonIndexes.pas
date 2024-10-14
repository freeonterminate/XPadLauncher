unit uButtonIndexes;

interface

uses
  PK.Device.GamePad.Types;

const
  B_NONE = -1;

  B_A = 0;
  B_A_P = 1;

  B_B = 2;
  B_B_P = 3;

  B_X = 4;
  B_X_P = 5;

  B_Y = 6;
  B_Y_P = 7;

  B_BACK = 8;
  B_BACK_P = 9;

  B_START = 10;
  B_START_P = 11;

  B_LB = 21;
  B_LB_P = 22;

  B_LS = 23;
  B_LS_P = 24;

  B_LT = 25;
  B_LT_P = 26;

  B_RB = 27;
  B_RB_P = 28;

  B_RS = 29;
  B_RS_P = 30;

  B_RT = 31;
  B_RT_P = 32;

  B_CROSS = 12;
  B_CROSS_D = B_CROSS + 1;
  B_CROSS_L = B_CROSS + 2;
  B_CROSS_R = B_CROSS + 3;
  B_CROSS_U = B_CROSS + 4;
  B_CROSS_LU = B_CROSS + 5;
  B_CROSS_LD = B_CROSS + 6;
  B_CROSS_RU = B_CROSS + 7;
  B_CROSS_RD = B_CROSS + 8;

  ST_L = 33;
  ST_L_D = ST_L + 1;
  ST_L_L = ST_L + 2;
  ST_L_R = ST_L + 3;
  ST_L_U = ST_L + 4;
  ST_L_LU = ST_L + 5;
  ST_L_LD = ST_L + 6;
  ST_L_RU = ST_L + 7;
  ST_L_RD = ST_L + 8;

  ST_R = 42;
  ST_R_D = ST_R + 1;
  ST_R_L = ST_R + 2;
  ST_R_R = ST_R + 3;
  ST_R_U = ST_R + 4;
  ST_R_LU = ST_R + 5;
  ST_R_LD = ST_R + 6;
  ST_R_RU = ST_R + 7;
  ST_R_RD = ST_R + 8;

  // Boolean Arrays
  B_As: array [Boolean] of Integer = (B_A, B_A_P);
  B_Bs: array [Boolean] of Integer = (B_B, B_B_P);
  B_Xs: array [Boolean] of Integer = (B_X, B_X_P);
  B_Ys: array [Boolean] of Integer = (B_Y, B_Y_P);

  B_BACKs: array [Boolean] of Integer = (B_BACK, B_BACK_P);
  B_STARTs: array [Boolean] of Integer = (B_START, B_START_P);

  B_LBs: array [Boolean] of Integer = (B_LB, B_LB_P);
  B_LSs: array [Boolean] of Integer = (B_LS, B_LS_P);
  B_LTs: array [Boolean] of Integer = (B_LT, B_LT_P);

  B_RBs: array [Boolean] of Integer = (B_RB, B_RB_P);
  B_RSs: array [Boolean] of Integer = (B_RS, B_RS_P);
  B_RTs: array [Boolean] of Integer = (B_RT, B_RT_P);

function GetImageIndex(const AStatus: TGamePadButtons): Integer;
function GetGamePadButton(const AImageIndex: Integer): TGamePadButton;

implementation

function GetImageIndex(const AStatus: TGamePadButtons): Integer;
begin
  Result := B_NONE;

  if TGamePadButton.A in AStatus then
    Result := B_A;

  if TGamePadButton.B in AStatus then
    Result := B_B;

  if TGamePadButton.X in AStatus then
    Result := B_X;

  if TGamePadButton.Y in AStatus then
    Result := B_Y;

  if TGamePadButton.Back in AStatus then
    Result := B_BACK;

  if TGamePadButton.Start in AStatus then
    Result := B_START;

  // L Buttons
  if TGamePadButton.LeftShoulder in AStatus then
    Result := B_LB;

  if TGamePadButton.LeftTrigger in AStatus then
    Result := B_LT;

  if TGamePadButton.LeftThumb in AStatus then
    Result := B_LS;

  // R Buttons
  if TGamePadButton.RightShoulder in AStatus then
    Result := B_RB;

  if TGamePadButton.RightTrigger in AStatus then
    Result := B_RT;

  if TGamePadButton.RightThumb in AStatus then
    Result := B_RS;

  // Cross
  if TGamePadButton.Up in AStatus then
    Result := B_CROSS_U;

  if TGamePadButton.Down in AStatus then
    Result := B_CROSS_D;

  if TGamePadButton.Left in AStatus then
    Result := B_CROSS_L;

  if TGamePadButton.Right in AStatus then
    Result := B_CROSS_R;

  if TGamePadButton.LeftUp in AStatus then
    Result := B_CROSS_LU;

  if TGamePadButton.LeftDown in AStatus then
    Result := B_CROSS_LD;

  if TGamePadButton.RightUp in AStatus then
    Result := B_CROSS_RU;

  if TGamePadButton.RightDown in AStatus then
    Result := B_CROSS_RD;

  // LStick
  if TGamePadButton.LStickL in AStatus then
    Result := ST_L_L;

  if TGamePadButton.LStickR in AStatus then
    Result := ST_L_R;

  if TGamePadButton.LStickU in AStatus then
    Result := ST_L_U;

  if TGamePadButton.LStickD in AStatus then
    Result := ST_L_D;

  if TGamePadButton.LStickLU in AStatus then
    Result := ST_L_LU;

  if TGamePadButton.LStickLD in AStatus then
    Result := ST_L_LD;

  if TGamePadButton.LStickRU in AStatus then
    Result := ST_L_RU;

  if TGamePadButton.LStickRD in AStatus then
    Result := ST_L_RD;

  // RStick
  if TGamePadButton.RStickL in AStatus then
    Result := ST_R_L;

  if TGamePadButton.RStickR in AStatus then
    Result := ST_R_R;

  if TGamePadButton.RStickU in AStatus then
    Result := ST_R_U;

  if TGamePadButton.RStickD in AStatus then
    Result := ST_R_D;

  if TGamePadButton.RStickLU in AStatus then
    Result := ST_R_LU;

  if TGamePadButton.RStickLD in AStatus then
    Result := ST_R_LD;

  if TGamePadButton.RStickRU in AStatus then
    Result := ST_R_RU;

  if TGamePadButton.RStickRD in AStatus then
    Result := ST_R_RD;
end;

function GetGamePadButton(const AImageIndex: Integer): TGamePadButton;
begin
  Result := TGamePadButton.None;

  if AImageIndex = B_A then
    Result := TGamePadButton.A;

  if AImageIndex = B_B then
    Result := TGamePadButton.B;

  if AImageIndex = B_X then
    Result := TGamePadButton.X;

  if AImageIndex = B_Y then
    Result := TGamePadButton.Y;

  if AImageIndex = B_BACK then
    Result := TGamePadButton.Back;

  if AImageIndex = B_START then
    Result := TGamePadButton.Start;

  // L Buttons
  if AImageIndex = B_LB then
    Result := TGamePadButton.LeftShoulder;

  if AImageIndex = B_LT then
    Result := TGamePadButton.LeftTrigger;

  if AImageIndex = B_LS then
    Result := TGamePadButton.LeftThumb;

  // R Buttons
  if AImageIndex = B_RB then
    Result := TGamePadButton.RightShoulder;

  if AImageIndex = B_RT then
    Result := TGamePadButton.RightTrigger;

  if AImageIndex = B_RS then
    Result := TGamePadButton.RightThumb;

  // Cross
  if AImageIndex = B_CROSS_U then
    Result := TGamePadButton.Up;

  if AImageIndex = B_CROSS_D then
    Result := TGamePadButton.Down;

  if AImageIndex = B_CROSS_L then
    Result := TGamePadButton.Left;

  if AImageIndex = B_CROSS_R then
    Result := TGamePadButton.Right;

  if AImageIndex = B_CROSS_LU then
    Result := TGamePadButton.LeftUp;

  if AImageIndex = B_CROSS_LD then
    Result := TGamePadButton.LeftDown;

  if AImageIndex = B_CROSS_RU then
    Result := TGamePadButton.RightUp;

  if AImageIndex = B_CROSS_RD then
    Result := TGamePadButton.RightDown;

  // LStick
  if AImageIndex = ST_L_L then
    Result := TGamePadButton.LStickL;

  if AImageIndex = ST_L_R then
    Result := TGamePadButton.LStickR;

  if AImageIndex = ST_L_U then
    Result := TGamePadButton.LStickU;

  if AImageIndex = ST_L_D then
    Result := TGamePadButton.LStickD;

  if AImageIndex = ST_L_LU then
    Result := TGamePadButton.LStickLU;

  if AImageIndex = ST_L_LD then
    Result := TGamePadButton.LStickLD;

  if AImageIndex = ST_L_RU then
    Result := TGamePadButton.LStickRU;

  if AImageIndex = ST_L_RD then
    Result := TGamePadButton.LStickRD;

  // RStick
  if AImageIndex = ST_R_L then
    Result := TGamePadButton.RStickL;

  if AImageIndex = ST_R_R then
    Result := TGamePadButton.RStickR;

  if AImageIndex = ST_R_U then
    Result := TGamePadButton.RStickU;

  if AImageIndex = ST_R_D then
    Result := TGamePadButton.RStickD;

  if AImageIndex = ST_R_LU then
    Result := TGamePadButton.RStickLU;

  if AImageIndex = ST_R_LD then
    Result := TGamePadButton.RStickLD;

  if AImageIndex = ST_R_RU then
    Result := TGamePadButton.RStickRU;

  if AImageIndex = ST_R_RD then
    Result := TGamePadButton.RStickRD;
end;

end.
