#!/usr/bin/perl

# Get gene data from aceserver and create an outfile with postgres commands for
# it, then execute it (as opposed to doing it on the fly since it takes 4 hours
# and data would not be there to use in the meantime).  2006 12 19
#
# Added a gin_wbgene table to show all wbgenes for Kimberly.  2008 05 01
#
# Copy of original using acedb account and local ws.  2009 08 31 
#
# Get some cosmid chromosome and ends for Jean-Louis (feedback@wormbase.org)
# 2009 12 28

use Ace;
use strict;
use diagnostics;
use Jex;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";

my @cosmids = qw( B0019 B0025 B0041 B0205 B0207 B0261 B0379 B0414 B0511 C01A2 C01F4 C01G8 C01H6 C03C11 C04F1 C04F12 C06A5 C07F11 C09D1 C09D4 C09H6 C10G11 C10H11 C11D9 C12C8 C15A11 C15C6 C16C2 C17D12 C17E4 C17F3 C17H1 C18E3 C24A11 C24G7 C25A1 C26C6 C27A12 C27C7 C30F12 C30F8 C30H7 C31H5 C32E12 C32E8 C32F10 C34B2 C34B7 C34G6 C35E7 C36B1 C36F7 C37A2 C37A5 C41D11 C41G7 C43E11 C43H8 C44E1 C44E4 C45E1 C45G3 C46H11 C47B2 C47F8 C48B6 C48E7 C49A1 C50F2 C53D5 C54G4 C54G6 C55B7 C55C2 CC4 D1007 D1037 D1081 D2005 D2030 D2092 DY3 E01A2 E03H4 F07A5 F08A10 F08A8 F09C3 F10D11 F10G8 F11A6 F11C3 F12B6 F13G3 F14B4 F14B6 F15C11 F15D3 F15H9 F16A11 F16C3 F16D3 F17B5 F18C12 F20G4 F21A9 F21C3 F21F12 F21F3 F22D6 F22G12 F23C8 F25D7 F25F1 F25F8 F25H2 F25H5 F26A3 F26B1 F26H9 F27C1 F27D4 F28B3 F28C12 F28D9 F28H1 F29C6 F29D10 F29D11 F30A10 F30F8 F31C3 F32A7 F32B4 F32B5 F32H2 F33D11 F33E2 F33H2 F35C12 F35E2 F36A2 F36D1 F36F2 F36H2 F37D6 F37F2 F39B2 F39H11 F39H2 F40E3 F41D3 F43G9 F44F1 F45H11 F46A8 F46A9 F46F11 F47G4 F47G6 F48C1 F49B2 F49D11 F52A8 F52B5 F52F12 F53B6 F53B8 F53F10 F53G12 F54A5 F54C1 F54D7 F55A12 F55A3 F55C7 F55D12 F55F8 F55H12 F56A3 F56A6 F56C11 F56F4 F56G4 F56H1 F56H6 F57B10 F57C9 F58D5 F58H10 F59A3 F59C6 H06O01 H15M21 H16D19 H25P06 H27M09 H31B20 H31G24 H32K16 H36N01 K02A11 K02B12 K02F2 K03D10 K03E5 K04F10 K04G2 K05C4 K06A5 K07A1 K07A12 K07A3 K07G5 K08C9 K09H9 K10C3 K10D3 K10E9 K11B4 K11D2 K12C11 M01A10 M01A12 M01B12 M01D7 M01E11 M01E5 M01G12 M04C9 M04D5 M05B5 R05D11 R05D7 R06A10 R06C1 R06C7 R09B3 R10A10 R119 R11A5 R12E2 R13H8 T01A4 T01G9 T01H8 T02E1 T02G6 T03A1 T03F1 T04D1 T04D3 T05E7 T05E8 T05F1 T06A4 T06D10 T06G6 T07D10 T08B2 T08G11 T09B4 T09E11 T10B11 T10E9 T12F5 T15D6 T19A6 T19B4 T20F10 T20F5 T21E12 T21E3 T22A3 T22C1 T22E7 T22H2 T23B3 T23D8 T23G11 T23H2 T23H4 T26E3 T27A3 T27C10 T27F6 T28B8 T28F2 T28F4 VF36H2L W01A8 W01B11 W02B9 W02D3 W02D9 W03D8 W03F11 W03G9 W04A4 W04A8 W04C9 W04G5 W05B5 W05F2 W05H12 W06D4 W09C3 W09C5 W09G3 W10C8 W10D5 Y105E8A Y105E8B Y106G6A Y106G6D Y106G6E Y106G6G Y106G6H Y110A7A Y119C1B Y18D10A Y18H1A Y20F4 Y23H5A Y23H5B Y26D4A Y34D9A Y34D9B Y37E3 Y37F4 Y37H9A Y39G10AR Y44E3A Y47D9A Y47G6A Y47H10A Y47H9B Y47H9C Y48G10A Y48G1A Y48G1BL Y48G1BM Y48G1BR Y48G1C Y48G8AL Y48G8AR Y50C1A Y51F10 Y52B11A Y52B11B Y53C10A Y53H1A Y53H1B Y53H1C Y54E10A Y54E10BL Y54E10BR Y54E5A Y54E5B Y63D3A Y65B4A Y65B4BL Y65B4BM Y65B4BR Y67A6A Y6B3A Y6B3B Y71A12B Y71A12C Y71F9AL Y71F9AM Y71F9AR Y71F9B Y71G12A Y71G12B Y73A3A Y74C10AM Y74C9A Y76G2A Y87G2A Y92H12A Y92H12BL Y92H12BR Y95B8A Y95D11A ZC123 ZC308 ZC328 ZC334 ZC434 ZC581 ZK1014 ZK1025 ZK1053 ZK1151 ZK1225 ZK256 ZK265 ZK270 ZK337 ZK39 ZK484 ZK524 ZK770 ZK849 ZK858 ZK909 ZK973 ZK993 2L52 2RSSE AH6 B0034 B0047 B0228 B0252 B0281 B0286 B0304 B0334 B0432 B0454 B0457 B0491 B0495 C01B12 C01B9 C01G12 C01G6 C03H5 C04A2 C04G6 C04H4 C04H5 C05D12 C06A1 C06A8 C06C3 C07D10 C07E3 C08B11 C08E3 C08F1 C08H9 C09D8 C09E8 C09G5 C09H10 C13B4 C14A4 C15F1 C16A11 C16C4 C16C8 C17A2 C17C3 C17F4 C17G10 C18A3 C18D1 C18E9 C18H9 C23H3 C24H12 C25H3 C26D10 C27A2 C27D6 C27H5 C29F5 C29H12 C30B5 C30G12 C31C9 C32B5 C32D5 C33B4 C33C12 C33F10 C34C6 C34F11 C38C6 C40A11 C40D2 C41C4 C41D7 C41H7 C44B7 C46E10 C46F9 C47D12 C47G2 C49D10 C50D2 C50E10 C52A11 C52E12 C52E2 C54A12 C56C10 C56E6 D1022 D1069 D2013 D2062 D2085 D2089 DH11 E01F3 E01G4 E02H1 E04D5 E04F6 EEED8 EGAP2 F01D5 F02E11 F07A11 F07E5 F07H5 F08B1 F08D12 F08G2 F09C12 F09D1 F09E5 F10B5 F10C1 F10E7 F10G7 F11G11 F12A10 F12E12 F13D12 F13H8 F14D2 F14E5 F14F11 F15A4 F15D4 F16G10 F18A1 F18A11 F18A12 F18C5 F19B10 F19H8 F21D12 F21H12 F22B5 F22D3 F22E5 F23F1 F26C11 F26G1 F26H11 F27E5 F28A10 F28B12 F28C6 F29A7 F29C12 F31D5 F31E8 F32A11 F32A5 F33A8 F33G12 F33H1 F33H12 F34D6 F35C11 F35C5 F35D11 F35D2 F35H8 F36H5 F37B1 F37B12 F37H8 F38A3 F39E9 F40E12 F40F8 F40H3 F40H7 F41C3 F41G3 F42G2 F42G4 F43C11 F43E2 F43G6 F44E5 F44F4 F44G4 F45C12 F45D11 F45E10 F45H10 F46C5 F46F5 F47F6 F48A11 F49C5 F49E12 F52C6 F52H3 F53A10 F53C3 F53G2 F54A3 F54B3 F54C9 F54D10 F54D12 F54D5 F54F11 F54H5 F55C12 F56D1 F56D12 F57C2 F57F10 F58A6 F58E1 F58F12 F58G1 F59A6 F59B10 F59E12 F59G1 F59H6 H12I13 H17B01 H20J04 H35N03 H41C03 H43E16 K01A2 K01C8 K02A2 K02B7 K02C4 K02E7 K02F6 K03H9 K04B12 K05F1 K05F6 K06A1 K07C10 K07D4 K07E8 K08A2 K08F8 K09E4 K09F6 K10B2 K10B4 K10G6 K10H10 K12D12 K12H6 M01D1 M02G9 M03A1 M05D6 M106 M110 M151 M176 M195 M28 R03C1 R03D7 R03H10 R05F9 R05G9 R05G9R R05H10 R05H5 R06A4 R06B9 R06F6 R07C3 R07G3 R09D1 R10H1 R11F4 R12C12 R153 R166 R52 R53 T01B7 T01D1 T01E8 T01H3 T02G5 T02H6 T04B8 T05A6 T05A7 T05A8 T05B9 T05C1 T05C12 T05H10 T06D4 T06D8 T07D3 T07D4 T07F8 T07H3 T08E11 T08H4 T09A5 T09F3 T10B9 T10D4 T11F1 T12C9 T13B5 T13C2 T13H5 T14B4 T14D7 T15G9 T15H9 T16A1 T19D12 T19E10 T19H5 T20H12 T21B10 T21B4 T22C8 T23F4 T24B8 T24E12 T24F1 T24H10 T24H7 T25D10 T25D3 T26C5 T27A1 T27D12 T27F7 T28D9 VF45E10L VM106R VT21B10L VW02B12L W01C9 W01D2 W01G7 W02B12 W02B8 W03C9 W04H10 W05H5 W06A11 W06B4 W07A12 W07E6 W07G1 W08F4 W09B6 W09E7 W09G10 W09H1 W10D9 W10G11 Y110A2AL Y110A2AM Y14H12A Y16E11A Y17G7A Y17G7B Y19D2B Y1E3A Y1H11 Y25C1A Y27F2A Y38E10A Y38F1A Y39F10B Y39F10C Y39G8B Y39G8C Y43F11A Y43H11AL Y46B2A Y46D2A Y46E12BL Y46E12BM Y46E12BR Y46G5A Y47G7A Y47G7B Y47G7C Y48B6A Y48C3A Y48E1A Y48E1B Y48E1C Y49F6A Y49F6B Y49F6C Y50F7A Y51B9A Y51H1A Y51H7BR Y51H7C Y52E8A Y53C12A Y53C12B Y53F4A Y53F4B Y54C5B Y54E2A Y54G11A Y54G11B Y54G9A Y57A10A Y57A10B Y57A10C Y57G7A Y62F5A Y6D1A Y74E4A Y81G3A Y8A9A Y9C2UA ZC101 ZC204 ZC239 ZK1067 ZK1127 ZK1131 ZK1240 ZK1248 ZK1290 ZK1307 ZK131 ZK1320 ZK1321 ZK177 ZK20 ZK250 ZK355 ZK546 ZK622 ZK666 ZK669 ZK673 ZK675 ZK75 ZK84 ZK892 ZK930 ZK938 ZK945 ZK970 ZK971 3R5 B0244 B0280 B0284 B0285 B0303 B0336 B0353 B0361 B0393 B0412 B0464 B0523 B0524 BE0003N10 BE10 C02C2 C02D5 C03B8 C03C10 C04D8 C05B5 C05D10 C05D11 C05D2 C05H8 C06E1 C06E8 C06G4 C07A9 C07G2 C07H6 C08C3 C09E7 C09F5 C13B9 C13G5 C14B1 C14B9 C15H7 C16A3 C16C10 C18D11 C18F10 C18H2 C23G10 C24A1 C24H11 C26E6 C27D11 C27F2 C28A5 C28H8 C29F9 C30A5 C30C11 C30D11 C32A3 C34C12 C34E10 C35D10 C36A4 C36E8 C38C10 C38D4 C38H2 C39B5 C40H1 C44B11 C44B9 C44F1 C45G9 C46F11 C48B4 C48D5 C50C3 C54C6 C56G2 C56G7 D1044 D2007 D2045 E02H9 E03A3 EGAP1 F01F1 F09F7 F09G8 F10C5 F10E9 F10F2 F11F1 F11H8 F13B10 F14F7 F17C8 F20H11 F21H11 F22B7 F23F12 F23H11 F25B5 F25F2 F26A1 F26F4 F27B3 F28F5 F30H5 F31E3 F34D10 F35G12 F37A4 F37A8 F37C12 F40F12 F40G9 F40H6 F42A10 F42G9 F42H10 F43C1 F44B9 F44E2 F45G2 F45H7 F47D12 F48E8 F52C9 F53A2 F53A3 F54C4 F54D8 F54E7 F54F2 F54G8 F54H12 F55H2 F56A8 F56C9 F56F11 F56F3 F57B9 F58A4 F58B6 F59A2 F59B2 H06I04 H09G03 H10E21 H14E04 H19M22 H38K22 K01A11 K01B6 K01F9 K01G5 K02F3 K03F8 K03H1 K04C2 K04G7 K04H4 K06H7 K07E12 K08E3 K08E5 K10D2 K10F12 K10G9 K11D9 K11H3 K12H4 M01A8 M01E10 M01F1 M01G4 M01G5 M03C11 M04D8 M142 M88 PAR3 R01H2 R02F2 R05D3 R05H11 R06B10 R07E5 R107 R10E11 R10E12 R10E4 R10E9 R10F2 R12B2 R13A5 R13F6 R13G10 R148 R151 R155 R17 R74 T02C1 T02C12 T03F6 T04A6 T04A8 T04C9 T05D4 T05G5 T07A5 T07C4 T07E3 T08A11 T12A2 T12B5 T12D8 T16G12 T16H12 T17A3 T17H7 T19C3 T20B12 T20B6 T20G5 T20H4 T20H9 T21C12 T21D11 T22F7 T23F11 T23G5 T24A11 T24C4 T25C8 T26A5 T26G10 T27D1 T27E9 T28A8 T28D6 W02B3 W03A3 W03A5 W04B5 W05B2 W05G11 W06E11 W06F12 W07B3 W09D10 W09D6 W10C4 Y102E9 Y111B2A Y119D3A Y119D3B Y1A5A Y22D7AL Y22D7AR Y32H12A Y34F4 Y37B11A Y37D8A Y39A1A Y39A1B Y39A1C Y39A3A Y39A3B Y39A3CL Y39E4A Y39E4B Y40D12A Y41C4A Y42G9A Y43F4A Y43F4B Y43F4C Y45F3A Y46E12A Y47D3A Y47D3B Y48A6B Y48A6C Y48G9A Y49E10 Y50D7A Y53G8AM Y53G8AR Y53G8B Y54F10AL Y54F10AM Y54F10BM Y54H5A Y55B1AL Y55B1BR Y55D5A Y56A3A Y66A7AL Y66A7AR Y66D12A Y67D2 Y69F12A Y70G10A Y71D11A Y71H2AL Y71H2AM Y71H2AR Y71H2B Y75B8A Y76A2A Y76A2B Y76A2C Y79H2A Y7G10A Y82E9BL Y82E9BR Y92C3A ZC21 ZC262 ZC47 ZC482 ZC84 ZK1010 ZK1058 ZK1098 ZK112 ZK1128 ZK121 ZK1236 ZK328 ZK353 ZK370 ZK418 ZK507 ZK512 ZK520 ZK525 ZK632 ZK637 ZK643 ZK652 ZK688 ZK783 4R79 AC7 B0001 B0035 B0212 B0218 B0273 B0350 B0478 B0496 B0513 B0545 B0546 B0547 B0564 C01B10 C01F6 C01G5 C02B10 C02F4 C04C3 C04G2 C05B10 C05C12 C05G6 C06A12 C06A6 C06E4 C06E7 C06G3 C06G8 C07C7 C07G1 C08F11 C08F8 C08G9 C09B9 C09G12 C09G4 C09G9 C10C5 C10C6 C10G6 C17H12 C18F3 C18H7 C23H5 C24D10 C24F3 C25A8 C25G4 C26B2 C26C9 C26H9A C27B7 C27D8 C27H2 C28C12 C28D4 C29E6 C29F4 C30H6 C31H1 C32H11 C33A12 C33D9 C33H5 C34D4 C34H4 C35B1 C35D6 C37F5 C39E9 C39H7 C42C1 C42D4 C43F9 C43G2 C44B12 C44C8 C45E5 C45G7 C46A5 C46C2 C46G7 C47A4 C47E12 C48A7 C48D1 C49A9 C49C3 C49C8 C49H3 C50A2 C50F7 C52D10 C53B4 C53D6 C54E4 C55C3 C55F2 CC8 D1046 D2024 D2096 E04A4 F01D4 F01G10 F01G4 F02H6 F07C6 F08B4 F08G5 F09C11 F09D12 F09E8 F11A10 F11E6 F12F6 F13B12 F13B6 F13E9 F13G11 F13H10 F14E12 F15B10 F15E6 F17E9 F18F11 F19B6 F19C7 F20C5 F20D12 F22B3 F23B2 F25H8 F26D10 F26D12 F27C8 F28D1 F28E10 F28F9 F29B9 F29C4 F30B5 F32B6 F32E10 F33D4 F35D6 F35F11 F35G2 F35H10 F36A4 F36H1 F36H12 F37C4 F38A1 F38A5 F38C2 F38E11 F38H4 F40F11 F42A6 F42A9 F42C5 F42G8 F44D12 F44E8 F45E4 F47C12 F49C12 F49C8 F49E11 F49E8 F49F1 F52B11 F52C12 F52G2 F53B2 F53H1 F54D1 F54E12 F55A8 F55B11 F55F10 F55G1 F55G11 F56A11 F56B3 F56C4 F56D5 F56D6 F56H11 F57H12 F58D2 F58E2 F58F6 F58F9 F58G6 F58H7 F59B8 H01G02 H02I12 H04M03 H06H21 H08G01 H08M01 H09I01 H10D12 H12I19 H16O14 H20E11 H21P03 H22D14 H23L24 H25K10 H32C10 H34C03 H35B03 JC8 K01A6 K01H12 K02B2 K02D7 K03D3 K03H6 K04D7 K06B9 K07A9 K07F5 K08B4 K08C7 K08D10 K08D12 K08D8 K08E4 K08E7 K08F11 K08F4 K09B11 K09E10 K10D11 K11E8 K11H12 LLC1 M01H9 M02B1 M02B7 M02G12 M03D4 M04B2 M04G7 M116 M117 M18 M199 M57 M7 M70 R02D3 R05A10 R05C11 R05G6 R07C12 R08C7 R09E10 R09H10 R102 R105 R10H10 R11A8 R11E3 R13 R13A1 R13H7 R13H9 T01B11 T01G1 T04A11 T04B2 T04C4 T05A1 T05A12 T05C7 T05E11 T06A10 T06C10 T07A9 T07G12 T08B6 T09A12 T11B7 T11F8 T11G6 T12A7 T12B3 T12E12 T12G3 T13A10 T13E8 T13F2 T13H10 T14A8 T14G10 T19E7 T21D12 T22B11 T22B3 T22D1 T23A7 T23B5 T23E1 T23F6 T23G4 T25B9 T26C12 T27E7 T28F3 T28H11 VY10G11R W01B6 W02A2 W02C12 W03B1 W03D2 W03F8 W03G1 W05E7 W07G9 W08D2 W08E12 W09C2 Y104H12D Y105C5A Y105C5B Y10G11A Y116A8A Y116A8B Y116A8C Y11D7A Y17G9A Y17G9B Y24D9A Y24F12A Y37A1A Y37A1B Y37E11AL Y37E11AM Y37E11AR Y37E11B Y38C1AA Y38C1AB Y38C1BA Y38F2AL Y38F2AR Y38H8A Y39C12A Y40C5A Y40D7A Y40H7A Y41D4A Y41D4B Y41E3 Y42H9AL Y42H9AR Y42H9B Y43B11AL Y43B11AM Y43B11AR Y43C5A Y43C5B Y43D4A Y43E12A Y45F10A Y45F10B Y45F10C Y45F10D Y46C8AL Y46C8AR Y48A5A Y4C6A Y4C6B Y51H4A Y54G2A Y55F3AL Y55F3AM Y55F3BL Y55F3BR Y55F3C Y55H10A Y55H10B Y57G11A Y57G11B Y57G11C Y59E9AL Y59H11AL Y59H11AM Y59H11AR Y5F2A Y62E10A Y64G10A Y65A5A Y65D7A Y66H1A Y66H1B Y67A10A Y67D8A Y67D8B Y67D8C Y67H2A Y68G5A Y69A2AL Y69A2AR Y69E1A Y73B6A Y73B6BL Y73B6BR Y73F4A Y73F8A Y76B12C Y77E11A Y7A9A Y7A9C Y7A9D Y94H6A Y9C9A ZC168 ZC410 ZC416 ZC477 ZC518 ZK1251 ZK180 ZK185 ZK354 ZK381 ZK550 ZK593 ZK596 ZK616 ZK617 ZK792 ZK795 ZK822 ZK829 ZK896 ZK897 AC3 AH10 B0024 B0213 B0222 B0238 B0240 B0250 B0331 B0348 B0365 B0391 B0399 B0462 B0507 B0554 C01B4 C01B7 C01G10 C02A12 C02E11 C02E7 C02H6 C03A7 C03E10 C03G6 C04E12 C04E6 C04F2 C04F5 C05A2 C05C8 C05E4 C06B3 C06B8 C06C6 C06H2 C06H5 C07G3 C08B6 C08D8 C08E8 C09H5 C10B5 C10F3 C10G8 C12D5 C12D8 C13A2 C13B7 C13D9 C13F10 C13G3 C14A6 C14B4 C14C10 C14C11 C14C6 C15C8 C15H11 C16D9 C17B7 C17E7 C18B10 C18C4 C18D4 C18G1 C24B5 C24B9 C24G6 C25A6 C25D7 C25E10 C25F9 C26E1 C26F1 C27A7 C29A12 C29F3 C31A11 C31B8 C31G12 C32C4 C33G8 C34B4 C34D1 C35A11 C35A5 C36C5 C37C3 C37H5 C38C3 C38D9 C39F7 C41G6 C43D7 C44C3 C44H9 C45B11 C45H4 C47A10 C47E8 C48G7 C49G7 C50B6 C50B8 C50C10 C50E3 C50F4 C50H11 C50H2 C51E3 C52A10 C52E4 C53A3 C53A5 C54D10 C54E10 C54F6 C54G10 C55A1 C55A6 C55H1 C56A3 CD4 cTel3X D1014 D1054 D1065 D1086 D2023 D2063 DC2 E02A10 E02C12 E03D2 F02C9 F02D8 F07B10 F07B7 F07C3 F07C4 F07D3 F07G11 F08E10 F08F3 F08H9 F09C6 F09F3 F09G2 F10A3 F10C2 F10D2 F10G2 F11A3 F11A5 F11D11 F12F3 F13A2 F13A7 F13H6 F14D1 F14D7 F14F8 F14F9 F14H3 F14H8 F15B9 F15E11 F15H10 F16B3 F16B4 F16H6 F17A9 F17C11 F18E2 F18E3 F19B2 F19F10 F20A1 F20D6 F20E11 F20G2 F21A3 F21C10 F21D9 F21E3 F21F8 F21H7 F22B8 F22F7 F23B12 F23H12 F25B3 F25B4 F25D1 F25E5 F25G6 F25H9 F26D11 F26D2 F26F12 F26F2 F26G5 F27B10 F27E11 F28A12 F28B1 F28C1 F28F8 F28G4 F28H7 F29F11 F29G9 F31D4 F31E9 F31F4 F32D1 F32D8 F32F2 F32G8 F32H5 F33E11 F35B12 F35E12 F35E8 F35F10 F36D3 F36D4 F36F12 F36G9 F36H9 F37B4 F38A6 F38B7 F38E1 F38H12 F39G3 F40A3 F40C5 F40D4 F40G12 F41B5 F41E6 F41F3 F41H8 F42E8 F43A11 F43D2 F43H9 F44A2 F44C4 F44C8 F44E7 F44G3 F45D3 F45F2 F46B3 F46B6 F46E10 F46F3 F47B8 F47C10 F47D2 F47G9 F47H4 F48F5 F48G7 F49A5 F49H6 F52E1 F52F10 F53B7 F53C11 F53E10 F53E4 F53F1 F53F4 F53F8 F53H10 F53H2 F54B8 F54D11 F54E2 F54F3 F55A11 F55B12 F55C10 F55C5 F55C9 F56A12 F56A4 F56E10 F56H9 F57A10 F57A8 F57B1 F57B7 F57E7 F57F4 F57F5 F57G4 F57G8 F58B4 F58E10 F58E6 F58G11 F58G4 F58H1 F59A1 F59A7 F59B1 F59D6 F59E11 H05B21 H10D18 H12C20 H12D21 H14N18 H19N07 H22D07 H23N18 H24D24 H24G06 H24K24 H27O22 H37A05 H39E23 H43I07 K01D12 K02E11 K02E2 K02H11 K03B4 K03B8 K03D7 K03H4 K04A8 K04F1 K06A4 K06B4 K06C4 K06H6 K07B1 K07C11 K07C5 K07C6 K08B12 K08D9 K08F9 K08G2 K08H10 K09C6 K09D9 K09G1 K09H11 K10C9 K10D6 K10G4 K11C4 K11D12 K11D5 K12B6 K12D9 K12F2 K12G11 M01B2 M02H5 M03E7 M03F8 M04C3 M04G12 M162 R01B10 R02C2 R02D5 R02F11 R03H4 R04B5 R04F11 R05D8 R07B5 R07B7 R08A2 R08E5 R08F11 R08H2 R09A1 R09B5 R09E12 R10D12 R10E8 R11D1 R11G10 R11G11 R11H6 R12A1 R12G8 R13D11 R13D7 R13H4 R186 R31 R90 T01C2 T01C4 T01D3 T01G5 T01G6 T02B11 T02B5 T02E9 T03D3 T03D8 T03E6 T03F7 T04C12 T04H1 T05B11 T05B4 T05C3 T05E12 T05G11 T05H4 T06A1 T06C12 T06E4 T06E6 T06E8 T07C12 T07F10 T07H8 T08B1 T08G3 T08H10 T09D3 T09E8 T09F5 T10B5 T10C6 T10G3 T10H4 T10H9 T11A5 T11F9 T13F3 T15B7 T16A9 T16G1 T19A5 T19B10 T19C4 T19C9 T19F4 T19H12 T20B3 T20C4 T20C7 T20D4 T21C9 T21H3 T22F3 T22G5 T22H9 T23B12 T23D5 T23F1 T24A6 T25E12 T25F10 T26E4 T26F2 T26H10 T26H2 T27B7 T27C4 T27C5 T27E4 T27F2 T28A11 T28B11 T28C12 T28F12 T28H10 VB0365 VC5 VF23B12L VK10D6R W01A11 W02D7 W02F12 W02G9 W02H5 W03F9 W04D2 W04E12 W05B10 W05E10 W06A7 W06D12 W06G6 W06H3 W06H8 W07A8 W07B8 W07G4 W08A12 W08G11 W09D12 Y102A5B Y102A5C Y102A5D Y113G7A Y113G7B Y113G7C Y116F11A Y116F11B Y17D7A Y17D7B Y19D10B Y20C6A Y22F5A Y24E3A Y2H9A Y32B12B Y32B12C Y32F6A Y32F6B Y32G9A Y36E3A Y37H2A Y37H2B Y38A10A Y38C9B Y38H6A Y38H6B Y38H6C Y39B6A Y39D8B Y39D8C Y39H10A Y40B10A Y40B10B Y40H4A Y42A5A Y43F8B Y43F8C Y44A6B Y44A6C Y44A6D Y45G12B Y45G12C Y45G5AL Y45G5AM Y45G5AR Y46H3A Y46H3C Y47A7 Y47D7A Y49C4A Y49G5A Y49G5B Y50D4A Y50D4B Y50D4C Y50E8A Y51A2A Y51A2D Y54B9A Y57E12AL Y57E12AR Y58A7A Y58G8A Y59A8A Y59A8B Y60A3A Y61A9LA Y61B8B Y68A4A Y68A4B Y69H2 Y6E2A Y6G8 Y70C5A Y70C5C Y73C8A Y73C8B Y73C8C Y75B12B Y75B7AL Y75B7AR Y75B7B Y80D3A Y94A7B Y97E10AM Y97E10AR Y97E10B Y97E10C ZC116 ZC132 ZC15 ZC178 ZC190 ZC196 ZC250 ZC266 ZC302 ZC317 ZC376 ZC404 ZC412 ZC443 ZC455 ZC487 ZC513 ZK1005 ZK1037 ZK105 ZK1055 ZK218 ZK228 ZK262 ZK287 ZK384 ZK40 ZK6 ZK682 ZK697 ZK742 ZK836 ZK856 ZK994 AC8 AH9 B0198 B0272 B0294 B0302 B0310 B0344 B0403 B0416 B0563 C01C10 C01C4 C02B4 C02B8 C02C6 C02D4 C02F12 C02H7 C03A3 C03B1 C03F11 C03G5 C03H12 C04A11 C04B4 C04C11 C04D1 C04E7 C04F6 C05C9 C05D9 C05E11 C05E7 C05G5 C06E2 C06G1 C07A12 C07A4 C07B5 C07D8 C08A9 C09B7 C09B8 C09C7 C09E10 C09F12 C09G1 C10A4 C10E2 C11E4 C11G10 C11G6 C11H1 C12D12 C14A11 C14E2 C14F11 C14F5 C14H10 C15A7 C15B12 C15C7 C15H9 C16B8 C16D6 C16H3 C17G1 C17H11 C18A11 C18B12 C18B2 C23F12 C23H4 C24A3 C24A8 C24H10 C25A11 C25B8 C25F6 C25G6 C26G2 C27C12 C28G1 C29F7 C30E1 C30F2 C30G4 C31E10 C31H2 C32A9 C33A11 C33D12 C33D3 C33E10 C33G3 C34D10 C34E11 C34E7 C34F6 C34H3 C35B8 C35C5 C36B7 C36C9 C36E6 C37E2 C38C5 C39B10 C39D10 C39E6 C40C9 C40H5 C41A3 C41G11 C42D8 C43C3 C43H6 C44C1 C44C10 C44H4 C45B2 C46E1 C46F2 C46F4 C47C12 C47D2 C48C5 C49F5 C49F8 C52B11 C52B5 C52B9 C52G5 C53B7 C53C11 C53C7 C53C9 C54D1 C54D2 C54G7 C54H2 C55B6 C56E10 C56G3 CE7X_3 D1005 D1009 D1025 D1053 D2021 E01G6 E01H11 E02H4 E03G2 EGAP4 EGAP7 EGAP8 F01E11 F01G12 F02C12 F02D10 F02E8 F07C7 F07G6 F08B12 F08C6 F08F1 F08G12 F09A5 F09B12 F09B9 F09C8 F09D5 F09E10 F09F9 F10D7 F11A1 F11C1 F11C7 F11D5 F13B9 F13C5 F13D11 F13D2 F13E6 F14B8 F14D12 F14F3 F14F4 F14H12 F15A2 F15A8 F15G10 F15G9 F16B12 F16F9 F16H11 F16H9 F17A2 F17E5 F17H10 F18E9 F18G5 F19C6 F19D8 F19G12 F19H6 F20B4 F20B6 F20D1 F21A10 F21E9 F21G4 F22A3 F22E10 F22F1 F22F4 F22H10 F23A7 F23C11 F23D12 F23G4 F25E2 F25H10 F26A10 F27D9 F28B4 F28H6 F29G6 F31A3 F31B12 F31B9 F31F6 F32A6 F33C8 F34H10 F35A5 F35B3 F35C8 F35G8 F35H12 F36G3 F38B2 F38B6 F38E9 F38G1 F39B1 F39B3 F39C12 F39D8 F39F10 F39H12 F40B5 F40E10 F40F4 F41B4 F41C6 F41D9 F41E7 F41G4 F42D1 F42E11 F42F12 F42G10 F43B10 F43C9 F44A6 F45B8 F45E1 F45E6 F46C3 F46C8 F46F2 F46F6 F46G10 F46H5 F46H6 F47A4 F47B10 F47B7 F47C8 F47E1 F47F2 F47G3 F48B9 F48C11 F48C5 F48D6 F48E3 F48F7 F49E10 F49E2 F49E7 F49H12 F52B10 F52D1 F52D10 F52D2 F52E10 F52E4 F52G3 F52H2 F53A9 F53B1 F53B3 F53H4 F53H8 F54B11 F54E4 F54F7 F54G2 F55A4 F55D10 F55E10 F55F1 F55F3 F55G7 F56B6 F56C3 F56E3 F56F10 F57C12 F57C7 F57G12 F58A3 F59C12 F59D12 F59F3 F59F4 F59F5 H01A20 H01M10 H02F09 H03A11 H03E18 H03G16 H05G16 H05L03 H06A10 H06K08 H08J11 H11E01 H13J03 H13N06 H18N23 H19J13 H20J18 H22K11 H28G03 H29C22 H30A04 H35N09 H36L18 H39E20 H40L08 K01A12 K02A4 K02A6 K02B9 K02D3 K02E10 K02G10 K02H8 K03A1 K03A11 K03C7 K03E6 K04C1 K04E7 K04G11 K05B2 K05G3 K06A9 K06G5 K08A8 K08B5 K08H2 K09A11 K09A9 K09C4 K09C8 K09E2 K09E3 K09F5 K10B3 K10C2 K11E4 K11G12 M02A10 M02D8 M02E1 M02F4 M03A8 M03B6 M03F4 M153 M163 M6 M60 M79 PDB1 R01E6 R02E12 R02E4 R03A10 R03E1 R03E9 R03G5 R03G8 R04A9 R04B3 R04D3 R04E5 R07A4 R07B1 R07D5 R07E3 R07E4 R08B4 R08E3 R09A8 R09F10 R09G11 R09H3 R106 R11 R11B5 R11G1 R12H7 R160 R173 R193 R57 SSSD1 T01B10 T01B4 T01B6 T01C1 T01H10 T02C5 T03G11 T03G6 T04C10 T04F8 T04G9 T05A10 T06F4 T06H11 T07C5 T07D1 T07F12 T07H6 T08A9 T08D2 T08G2 T09B9 T10A3 T10B10 T10E10 T10H10 T13C5 T13G4 T13H2 T14E8 T14F9 T14G11 T14G12 T14G8 T18D3 T19C11 T19D2 T19D7 T20B5 T20F7 T21B6 T21D9 T21E8 T21F2 T21F4 T21H8 T22B7 T22E5 T22E6 T22H6 T23C6 T23E7 T23F2 T24C12 T24C2 T24D11 T24D3 T24D5 T25B2 T25B6 T25C12 T25D1 T25G12 T26C11 T27A10 T27A8 T27B1 T28B4 VB0395L VF13E6L VK04G11 VY35H6BL W01C8 W01H2 W03G11 W03H1 W04G3 W05H7 W05H9 W06B11 W06B3 W07E11 W09B12 W10G6 Y102A11A Y102F5A Y108F1 Y12A6A Y15E3A Y16B4A Y1B5A Y26E6A Y34B4A Y35H6 Y40A1A Y40C7B Y41G9A Y47C4A Y48D7A Y49A10A Y59E1A Y59E1B Y60A9A Y62H9A Y64H9A Y66C5A Y67D11A Y70D2A Y71H10A Y71H9A Y72A10A Y73B3A Y73B3B Y75D11A Y76F7A Y7A5A Y80E2A Y81B9A ZC13 ZC373 ZC374 ZC449 ZC504 ZC506 ZC53 ZC64 ZC8 ZK1073 ZK1086 ZK1193 ZK154 ZK377 ZK380 ZK402 ZK455 ZK470 ZK54 ZK563 ZK662 ZK678 ZK721 ZK813 ZK816 ZK867 ZK899 );

# my $directory = '/home/acedb/work/get_stuff';
# chdir($directory) or die "Cannot go to $directory ($!)";

# my $count_value = 0;
# if ($ARGV[0]) { $count_value = $ARGV[0]; }

my $start = &getSimpleSecDate();

# use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
# use constant PORT => $ENV{ACEDB_PORT} || 2005;
# my $db = Ace->connect(-host=>HOST,-port=>PORT) or warn "Connection failure: ",Ace->error;

my $database_path = "/home3/acedb/ws/acedb";	# full path to local AceDB database; change as appropriate
my $program = "/home/acedb/bin/tace";		# full path to tace; change as appropriate
my $db = Ace->connect(-path => $database_path,  -program => $program) || die print "Connection failure: ", Ace->error;	# local database


my $query="find Clone";
# my @tags = qw( Mail Representative Registered_lab_members );
foreach my $cosmid (@cosmids) {
  my $squery = $query . " $cosmid";
  my @objs=$db->fetch(-query=>$squery);
  my @result;
  push @result, $cosmid;
  my $map = '';
  my $tag = 'Map';
  if ($objs[0]->$tag) { $map = $objs[0]->$tag; }
  push @result, $map;
  my $obj = $objs[0]->fetch->asString;
  my $left = ''; my $right = '';
  if ($obj =~ m/Left\s+(\d+)/) { $left = $1; }
  if ($obj =~ m/Right\s+(\d+)/) { $right = $1; }
  push @result, $left;
  push @result, $right;
  my $result = join"\t", @result;
  print "$result\n";
#   print "OB $obj OB\n";
}

__END__

  # START LAB #
my $query="find Laboratory";
my @tags = qw( Mail Representative Registered_lab_members );

my @objs=$db->fetch(-query=>$query);

if (! @objs) { print "no objects found.\n"; }
else {
  my %std_name;
  my $result = $dbh->prepare( "SELECT * FROM two_standardname;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $row[0] =~ s/two/WBPerson/; $std_name{$row[0]} = $row[2]; }

  my $all_stuff;
  foreach my $obj (@objs) {
    $all_stuff .= "Lab designation : $obj\n";
  #   print "Lab designation : $obj\n";
    foreach my $tag (@tags) {
      foreach ($obj->$tag(1)) {
        if ($std_name{$_}) { $all_stuff .= "$tag\t$std_name{$_} ($_)\n"; }
          else { $all_stuff .= "$tag\t$_\n"; }
      }
    } # foreach my $tag (@tags)
    $all_stuff .= "\n";
  }

  my (@length) = split/./, $all_stuff;
  if (scalar(@length) > 1000) {
    my $outfile_labs = 'out/labs.ace';
    open (OUT, ">$outfile_labs") or die "Cannot open $outfile_labs : $!";
    print OUT "$all_stuff";
    close (OUT) or die "Cannot close $outfile_labs : $!";
  }
}
  # END LAB #




my $outfile = 'out/gin_main.' . $start . '.pg';
if ($ARGV[1]) { $outfile = $ARGV[1]; }
open (PG, ">>$outfile") or die "Cannot create $outfile : $!";
print PG "-- $start\n\n";


$query="find Gene WBGene*";

my @genes=$db->fetch(-query=>$query);

# # if ($count_value == 0) { @genes = $db->list('Gene', 'WBGene*'); }	# when given 0000, this would not loop over WBGene0000, it would loop over everything, which is not what's intended  2008 01 10
# # if ($count_value eq '0') { @genes = $db->list('Gene', 'WBGene00009998'); }
# if ($count_value eq '0') { @genes = $db->list('Gene', 'WBGene*'); }
#   else { 
#     my $search = 'WBGene' . $count_value . '*';
#     print PG "-- \@genes = \$db->list('Gene', '$search');\n"; 
#     @genes = $db->list('Gene', $search); }


# my $result = '';

print PG "DELETE FROM gin_sequence;\n";
print PG "DELETE FROM gin_protein;\n";
print PG "DELETE FROM gin_seqprot;\n";
print PG "DELETE FROM gin_synonyms;\n";
print PG "DELETE FROM gin_seqname;\n";
print PG "DELETE FROM gin_molname;\n";
print PG "\n\n";

my $count = 0;
my $syn_count = 0;			# count synonyms INSERTs to see if good or not
my $email_message = '';
foreach my $object (@genes) {

  $count++;
#   last if ($count > 10);
  my $is_good = 0;

#   print "$object\n\n";

  my ($joinkey) = $object =~ m/(\d+)/;
# doing this in populate_gin_locus now  2008 05 31
#   my $command = "INSERT INTO gin_wbgene VALUES ('$joinkey', '$object');";
#   print PG "$command\n";
#   print PG "-- $object\tgin_wbgene\n"; 

  my @junk = $object->CGC_name;			# these mean there's data even if we're not capturing it
  foreach my $a (@junk) { $is_good++; }
  @junk = $object->Public_name;			# these mean there's data even if we're not capturing it
  foreach my $a (@junk) { $is_good++; }
  my @a = $object->Other_name;
  foreach my $a (@a) {
    my $locus = 'other';
    if ($a =~ m/\w{3,4}\-\d+/) { $locus = 'locus'; }
    my $command = "INSERT INTO gin_synonyms VALUES ('$joinkey', '$a', '$locus');";
    $syn_count++;
    $is_good++;
    print PG "$command\n";
#     $result = $conn->exec( $command );
    print PG "-- $object\tOth\t$a\n"; 
  }
  my @b = $object->Sequence_name;
  foreach my $b (@b) { 
    my $command = "INSERT INTO gin_seqname VALUES ('$joinkey', '$b');";
    $is_good++;
    print PG "$command\n";
#     $result = $conn->exec( $command );
    print PG "-- $object\tSequence_name\t$b\n"; }
  @b = $object->Molecular_name;
  foreach my $b (@b) { 
    my $command = "INSERT INTO gin_molname VALUES ('$joinkey', '$b');";
    $is_good++;
    print PG "$command\n";
#     $result = $conn->exec( $command );
    print PG "-- $object\tMolecular_name\t$b\n"; }
  my @c = $object->Corresponding_CDS;
  foreach my $c (@c) {
    my $command = "INSERT INTO gin_sequence VALUES ('$joinkey', '$c');";
    $is_good++;
    print PG "$command\n";
#     $result = $conn->exec( $command );
    my $d = '';
    $d = $c->Corresponding_protein;
    if ($d) { 
        my $command = "INSERT INTO gin_protein VALUES ('$joinkey', '$d');";
        print PG "$command\n";
#         $result = $conn->exec( $command );
        $command = "INSERT INTO gin_seqprot VALUES ('$joinkey', '$c', '$d');";
        print PG "$command\n";
#         $result = $conn->exec( $command );
        print PG "-- $object\tCDS\t$c\tCorr\t$d\n"; }
      else { 
        print PG "-- $object\tCDS\t$c\n"; }
  }
  my @e = $object->Corresponding_Transcript;
  foreach my $e (@e) { 
    my $command = "INSERT INTO gin_sequence VALUES ('$joinkey', '$e');";
    $is_good++;
    print PG "$command\n";
#     $result = $conn->exec( $command );
    print PG "-- $object\tTranscript\t$e\n"; }

  print PG "\n";
  unless ($is_good > 0) { $email_message .= "$object does not have data\n"; }
}

my $end = &getSimpleSecDate();
print PG "\n-- $end\n";

close (PG) or die "Cannot create $outfile : $!";

my $user = 'populate_gin.pl';
my $email = 'vanauken@its.caltech.edu';
my $subject = 'populate_gin.pl result';
my $body = "There are $count wbgenes\n";
if ($ARGV[0]) { $body .= "For wbgenes starting with WBGene$ARGV[0]\n"; }
$body .= "\n$email_message";
&mailer($user, $email, $subject, $body);

if ($syn_count > 10000) {
  `psql -e testdb < $outfile`;			# read in the generated data
}
