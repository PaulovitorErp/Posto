#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TPDVP026 (LJ1144Im)
Permite o filtro dos dados importados pela rotina de importação dos dados da carga da Venda Assistida Off-Line.

@author Pablo Cavalcante
@since 05/02/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TPDVP026()

Local cTable  := ParamIxb[1] //Tabela sendo importada.
//Local cBranch := ParamIxb[2] //Filial sendo importada.
Local lSkip   := .F. //Se pula (.T.) ou não (.F.) a importação do registro.

Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente)
//Caso o Posto Inteligente não esteja habilitado não faz nada...
If !lMvPosto
	Return lSkip
EndIf
	
	//TODO - sempre que "reaproveitar" uma tabela da versão antica, verificar se o alias esta nesta lista
	lSkip := cTable $ 'SZ0;U05;U06;U07;U08;U09;U10;U11;U12;U13;U14;U15;U16;U17;U18;U19;U20;U21;U22;U23;U24;U26;U27;U28;U29;U30;U31;U32;U33;U34;U35;U36;U37;U38;U39;U40;U41;U42;U43;U45;U47;U48;U49;U50;U51;U58;U60;U61;U62;U63;U64;U67;U69;U70;U71;U73;U74;U83;U87;U90;U93;U94;U96;U97;U98;U99;UA0;UA6;UA9;UAA;UAB;UAC;UAE;UAP;UAQ;UB0;UB5;UB6;UB7;UB8;UC0;UC1;UC6;UF0;UF3;UF4;UF7;UF8;UF9;UFA;UG0;UG1;UG2;UG3;UG4;UG5;UG6;UG7;UG8;UG9;UH0;UH1;UH5;UI3;UI4;UI5;UI6;UL4;ZE1;ZE2'

Return lSkip
