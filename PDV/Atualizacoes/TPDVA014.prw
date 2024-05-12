#include 'poscss.ch'
#include "TOTVS.CH"
#include 'stpos.ch'
#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TOPCONN.CH'
#include "rwmake.ch"
#INCLUDE "tbiconn.ch"

Static aBkpCF := {} //variável para fazer backup dos dados digitados

/*/{Protheus.doc} TPDVA014
Cálculo do saldo de carta frete no Totvs PDV

@author Pablo Nunes
@since 28/06/2023
@version 1.0
@type function
/*/
User Function TPDVA014(cCodCF,cLojCF)
	Local oPanelCTF

	Local oSay1
	Local oSay2
	Local oSay3
	Local oSay4
	Local oSay5
	//Local oSay6
	Local oSay7
	Local oSay8
	Local oSay9
	Local oSay10
	Local oSay11
	Local oSay12
	Local oSay13
	Local oSay14
	Local oSay15
	Local oSay16
	Local oSay17
	Local oSay18
	Local oSay19
	Local oSay20
	Local oSay21
	Local oSay22
	Local oSay23
	Local oSay25
	Local oSay26
	Local oSay27
	Local oSay28
	Local oSay29
	Local oSay30

	Private oButton1
	Private oButton2
	Private oButton3
	Private oGet1
	Private nGet1 := 0
	Private oGet2
	Private nGet2 := 0
	Private oGet3
	Private nGet3 := 0
	Private oGet4
	Private nGet4 := 0
	Private oGet5
	Private nGet5 := 0
	Private oGet6
	Private cGet6 := "NÃO"
	Private oGet7
	Private nGet7 := 0
	Private oGet8
	Private nGet8 := 0
	Private oGet9
	Private nGet9 := 0
	Private oGet10
	Private nGet10 := 0
	Private oGet11
	Private nGet11 := 0
	Private oGet12
	Private nGet12 := 0
	Private oGet13
	Private dGet13 := Date()
	Private oGet14
	Private cGet14 := SPACE(120)
	Private oGet15
	Private nGet15 := 0
	Private oGet16
	Private nGet16 := 0
	Private oGet17
	Private nGet17 := 0
	Private oGet18
	Private nGet18 := 0
	Private oGet19
	Private nGet19 := 0
	Private oGet20
	Private nGet20 := 0
	Private oGet21
	Private nGet21 := 0
	Private oGet22
	Private nGet22 := 0
	Private oGet23
	Private nGet23 := 0
	Private oGet24
	Private nGet24 := 0
	Private oGet25
	Private nGet25 := 0
	Private oGet26
	Private nGet26 := 0
	Private oGet27
	Private nGet27 := 0
	Private oGet28
	Private nGet28 := 0
	Private oGet29
	Private nGet29 := 0
	Private oGet30
	Private nGet30 := 0

	Private cCodEmCF := ""
	Private cLojEmCF := ""

	Private oRadMenu1
	Private nRadMenu1 := 1

	Static oDlgSldCtf

	cCodEmCF := cCodCF
	cLojEmCF := cLojCF

	SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
	If Empty(cCodEmCF) .or. !SA1->(DbSeek(xFilial("SA1")+cCodEmCF+cLojEmCF))
		alert("Selecione um emitente de carta frete.")
		Return nGet30
	EndIf

	SetKey(VK_F3, {|| })

	DEFINE MSDIALOG oDlgSldCtf TITLE "" FROM 000, 000 TO 640, 800 PIXEL STYLE nOr(WS_VISIBLE, WS_POPUP)

	nWidth  := (oDlgSldCtf:nWidth/2)
	nHeight := (oDlgSldCtf:nHeight/2)

	@ 000, 000 MSPANEL oPnlTop SIZE nWidth, 017 OF oDlgSldCtf
	oPnlTop:SetCSS( POSCSS (GetClassName(oPnlTop), CSS_BAR_TOP ))
	@ 004, 005 SAY oSayTop PROMPT " Cálculo de Saldo Carta Frete " SIZE 150, 015 OF oPnlTop COLORS 0, 16777215 PIXEL
	oSayTop:SetCSS( POSCSS (GetClassName(oSayTop), CSS_BREADCUMB ))
	oClose := TBtnBmp2():New( 002,oDlgSldCtf:nWidth-25,20,30,'FWSKIN_DELETE_ICO',,,,{|| oDlgSldCtf:End() },oPnlTop,,,.T. )
	oClose:SetCss("TBtnBmp2{border: none;background-color: none;}")

	@ 017, 000 MSPANEL oPanelCTF SIZE nWidth, nHeight-017 OF oDlgSldCtf
	oPanelCTF:SetCSS( "TPanel{border: 2px solid #999999; background-color: #f4f4f4;}" )

	// --- PRIMEIRO QUADRANTE ---
	@ 000, 000 MSPANEL oPanel1 SIZE 124, 075 OF oPanelCTF COLORS 0, 16777215
	oPanel1:SetCSS( POSCSS (GetClassName(oPanel1), CSS_PANEL_CONTEXT ))

	@ 002, 005 SAY oSayGrp1 PROMPT " Diferença de Peso " SIZE (oPanel1:nWidth/2)-010, 015 OF oPanel1 COLORS 0, 16777215 PIXEL CENTER
	oSayGrp1:SetCSS( POSCSS (GetClassName(oSayGrp1), CSS_BTN_FOCAL ))
	@ 019, 005 SAY oSayGrp1 PROMPT "" SIZE 001, 052 OF oPanel1 COLORS 0, 16777215 PIXEL CENTER
	oSayGrp1:SetCSS( POSCSS (GetClassName(oSayGrp1), CSS_BTN_FOCAL ))

	@ 021, 010 SAY oSay1 PROMPT "Peso carga saída (kg)" SIZE 055, 008 OF oPanel1 COLORS 0, 16777215 PIXEL
	oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
	@ 019, 070 MSGET oGet1 VAR nGet1 SIZE 050, 013 OF oPanel1 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL
	oGet1:SetCSS( POSCSS (GetClassName(oGet1), CSS_GET_NORMAL ))

	@ 039, 010 SAY oSay2 PROMPT "Peso descarga (kg)" SIZE 055, 008 OF oPanel1 COLORS 0, 16777215 PIXEL
	oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))
	@ 037, 070 MSGET oGet2 VAR nGet2 SIZE 050, 013 OF oPanel1 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL
	oGet2:SetCSS( POSCSS (GetClassName(oGet2), CSS_GET_NORMAL ))

	@ 057, 010 SAY oSay3 PROMPT "Diferença (kg)" SIZE 055, 008 OF oPanel1 COLORS 0, 16777215 PIXEL
	oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
	@ 055, 070 MSGET oGet3 VAR nGet3 SIZE 050, 013 OF oPanel1 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL READONLY
	oGet3:SetCSS( POSCSS (GetClassName(oGet3), CSS_GET_NORMAL ))

	// --- SEGUNDO QUADRANTE ---
	@ 000, 124 MSPANEL oPanel2 SIZE 124, 075 OF oPanelCTF COLORS 0, 16777215
	oPanel2:SetCSS( POSCSS (GetClassName(oPanel2), CSS_PANEL_CONTEXT ))

	@ 002, 005 SAY oSayGrp2 PROMPT " Cálculo da Tolerância " SIZE (oPanel2:nWidth/2)-010, 015 OF oPanel2 COLORS 0, 16777215 PIXEL CENTER
	oSayGrp2:SetCSS( POSCSS (GetClassName(oSayGrp2), CSS_BTN_FOCAL ))
	@ 019, 005 SAY oSayGrp2 PROMPT "" SIZE 001, 052 OF oPanel2 COLORS 0, 16777215 PIXEL CENTER
	oSayGrp2:SetCSS( POSCSS (GetClassName(oSayGrp2), CSS_BTN_FOCAL ))

	@ 021, 010 SAY oSay4 PROMPT "Tolerância (%)" SIZE 055, 008 OF oPanel2 COLORS 0, 16777215 PIXEL
	oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
	@ 019, 070 MSGET oGet4 VAR nGet4 SIZE 050, 013 OF oPanel2 VALID CalcSaldo() PICTURE "@E 99.99" COLORS 0, 16777215 PIXEL
	oGet4:SetCSS( POSCSS (GetClassName(oGet4), CSS_GET_NORMAL ))

	@ 039, 010 SAY oSay5 PROMPT "Peso tolerância (kg)" SIZE 055, 008 OF oPanel2 COLORS 0, 16777215 PIXEL
	oSay5:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
	@ 037, 070 MSGET oGet5 VAR nGet5 SIZE 050, 013 OF oPanel2 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL READONLY
	oGet5:SetCSS( POSCSS (GetClassName(oGet5), CSS_GET_NORMAL ))

	// --- TERCEIRO QUADRANTE ---
	@ 085, 000 MSPANEL oPanel3 SIZE 124, 050 OF oPanelCTF COLORS 0, 16777215
	oPanel3:SetCSS( POSCSS (GetClassName(oPanel3), CSS_PANEL_CONTEXT ))

	@ 000, 005 SAY oSayGrp3 PROMPT " Critério da Quebra " SIZE (oPanel3:nWidth/2)-010, 015 OF oPanel3 COLORS 0, 16777215 PIXEL CENTER
	oSayGrp3:SetCSS( POSCSS (GetClassName(oSayGrp3), CSS_BTN_FOCAL ))
	@ 017, 005 SAY oSayGrp3 PROMPT "" SIZE 001, 034 OF oPanel3 COLORS 0, 16777215 PIXEL CENTER
	oSayGrp3:SetCSS( POSCSS (GetClassName(oSayGrp3), CSS_BTN_FOCAL ))

	@ 023, 015 MSGET oGet6 VAR cGet6 SIZE 028, 013 OF oPanel3 COLORS 0, 16777215 PIXEL READONLY
	oGet6:SetCSS( POSCSS (GetClassName(oGet6), CSS_GET_NORMAL ))
	@ 021, 065 RADIO oRadMenu1 VAR nRadMenu1 ITEMS "INTEGRAL","PARCIAL" SIZE 043, 017 OF oPanel3 COLOR CLR_GRAY, 16777215 PIXEL WHEN (nGet5<nGet3)
	oRadMenu1:bChange := {|| CalcSaldo("nRadMenu1")}

	// --- QUARTO QUADRANTE ---
	@ 085, 124 MSPANEL oPanel4 SIZE 124, 050 OF oPanelCTF COLORS 0, 16777215
	oPanel4:SetCSS( POSCSS (GetClassName(oPanel4), CSS_PANEL_CONTEXT ))

	@ 000, 005 SAY oSayGrp4 PROMPT " Cálculo do Frete sem Descontos " SIZE (oPanel4:nWidth/2)-010, 015 OF oPanel4 COLORS 0, 16777215 PIXEL CENTER
	oSayGrp4:SetCSS( POSCSS (GetClassName(oSayGrp4), CSS_BTN_FOCAL ))
	@ 017, 005 SAY oSayGrp4 PROMPT "" SIZE 001, 034 OF oPanel4 COLORS 0, 16777215 PIXEL CENTER
	oSayGrp4:SetCSS( POSCSS (GetClassName(oSayGrp4), CSS_BTN_FOCAL ))

	@ 019, 010 SAY oSay7 PROMPT "Peso menor (kg)" SIZE 055, 008 OF oPanel4 COLORS 0, 16777215 PIXEL
	oSay7:SetCSS( POSCSS (GetClassName(oSay7), CSS_LABEL_FOCAL ))
	@ 017, 070 MSGET oGet7 VAR nGet7 SIZE 050, 013 OF oPanel4 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL READONLY
	oGet7:SetCSS( POSCSS (GetClassName(oGet7), CSS_GET_NORMAL ))

	@ 037, 010 SAY oSay8 PROMPT "Frete combin/ton (R$)" SIZE 055, 008 OF oPanel4 COLORS 0, 16777215 PIXEL
	oSay8:SetCSS( POSCSS (GetClassName(oSay8), CSS_LABEL_FOCAL ))
	@ 035, 070 MSGET oGet8 VAR nGet8 SIZE 050, 013 OF oPanel4 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL
	oGet8:SetCSS( POSCSS (GetClassName(oGet8), CSS_GET_NORMAL ))

	// --- QUINTO QUADRANTE ---
	@ 144, 000 MSPANEL oPanel5 SIZE 250, 100 OF oPanelCTF COLORS 0, 16777215
	oPanel5:SetCSS( POSCSS (GetClassName(oPanel5), CSS_PANEL_CONTEXT ))

	@ 003, 005 SAY oSayGrp5 PROMPT " Cálculo da Quebra " SIZE (oPanel5:nWidth/2)-010, 015 OF oPanel5 COLORS 0, 16777215 PIXEL CENTER
	oSayGrp5:SetCSS( POSCSS (GetClassName(oSayGrp5), CSS_BTN_FOCAL ))
	@ 020, 005 SAY oSayGrp5 PROMPT "" SIZE 001, 068 OF oPanel5 COLORS 0, 16777215 PIXEL CENTER
	oSayGrp5:SetCSS( POSCSS (GetClassName(oSayGrp5), CSS_BTN_FOCAL ))

	@ 022, 010 SAY oSay9 PROMPT "Valor da mercadoria (R$)" SIZE 120, 008 OF oPanel5 COLORS 0, 16777215 PIXEL
	oSay9:SetCSS( POSCSS (GetClassName(oSay9), CSS_LABEL_FOCAL ))
	@ 020, 194 MSGET oGet9 VAR nGet9 SIZE 050, 013 OF oPanel5 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL WHEN (nGet5<nGet3)
	oGet9:SetCSS( POSCSS (GetClassName(oGet9), CSS_GET_NORMAL ))

	@ 040, 010 SAY oSay10 PROMPT "Peso carga saída (kg)" SIZE 120, 008 OF oPanel5 COLORS 0, 16777215 PIXEL
	oSay10:SetCSS( POSCSS (GetClassName(oSay10), CSS_LABEL_FOCAL ))
	@ 038, 194 MSGET oGet10 VAR nGet10 SIZE 050, 013 OF oPanel5 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL READONLY
	oGet10:SetCSS( POSCSS (GetClassName(oGet10), CSS_GET_NORMAL ))

	@ 058, 010 SAY oSay11 PROMPT "Valor / quebra (R$/kg)" SIZE 120, 008 OF oPanel5 COLORS 0, 16777215 PIXEL
	oSay11:SetCSS( POSCSS (GetClassName(oSay11), CSS_LABEL_FOCAL ))
	@ 056, 194 MSGET oGet11 VAR nGet11 SIZE 050, 013 OF oPanel5 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL READONLY
	oGet11:SetCSS( POSCSS (GetClassName(oGet11), CSS_GET_NORMAL ))

	@ 076, 010 SAY oSay12 PROMPT "Valor a ser descontado (R$)" SIZE 120, 008 OF oPanel5 COLORS 0, 16777215 PIXEL
	oSay12:SetCSS( POSCSS (GetClassName(oSay12), CSS_LABEL_FOCAL ))
	@ 074, 194 MSGET oGet12 VAR nGet12 SIZE 050, 013 OF oPanel5 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL READONLY
	oGet12:SetCSS( POSCSS (GetClassName(oGet12), CSS_GET_NORMAL ))

	// --- SEXTO QUADRANTE ---
	@ 245, 000 MSPANEL oPanel6 SIZE 250, 050 OF oPanelCTF COLORS 0, 16777215
	oPanel6:SetCSS( POSCSS (GetClassName(oPanel6), CSS_PANEL_CONTEXT ))

	@ 000, 005 SAY oSayGrp6 PROMPT "" SIZE (oPanel6:nWidth/2)-010, 015 OF oPanel6 COLORS 0, 16777215 PIXEL CENTER
	oSayGrp6:SetCSS( POSCSS (GetClassName(oSayGrp6), CSS_BTN_FOCAL ))
	@ 017, 005 SAY oSayGrp6 PROMPT "" SIZE 001, 068 OF oPanel6 COLORS 0, 16777215 PIXEL CENTER
	oSayGrp6:SetCSS( POSCSS (GetClassName(oSayGrp6), CSS_BTN_FOCAL ))

	@ 019, 010 SAY oSay13 PROMPT "Data" SIZE 055, 008 OF oPanel6 COLORS 0, 16777215 PIXEL
	oSay13:SetCSS( POSCSS (GetClassName(oSay13), CSS_LABEL_FOCAL ))
	@ 017, 070 MSGET oGet13 VAR dGet13 SIZE 050, 013 OF oPanel6 COLORS 0, 16777215 PIXEL READONLY
	oGet13:SetCSS( POSCSS (GetClassName(oGet13), CSS_GET_NORMAL ))

	@ 037, 010 SAY oSay14 PROMPT "Responsável" SIZE 055, 008 OF oPanel6 COLORS 0, 16777215 PIXEL
	oSay14:SetCSS( POSCSS (GetClassName(oSay14), CSS_LABEL_FOCAL ))
	@ 035, 070 MSGET oGet14 VAR cGet14 SIZE 175, 013 OF oPanel6 COLORS 0, 16777215 PIXEL
	oGet14:SetCSS( POSCSS (GetClassName(oGet14), CSS_GET_NORMAL ))

	//TODO - escodo o panel de Data/Responsável pois não será utilizado, caso não tenha impressão
	oPanel6:Hide()

	// --- SETIMO QUADRANTE ---
	@ 000, 250 MSPANEL oPanel7 SIZE 152, 275 OF oPanelCTF COLORS 0, 16777215
	oPanel7:SetCSS( POSCSS (GetClassName(oPanel7), CSS_PANEL_CONTEXT ))

	@ 002, 005 SAY oSayGrp7 PROMPT " Cálculo do Frete Final " SIZE (oPanel7:nWidth/2)-010, 015 OF oPanel7 COLORS 0, 16777215 PIXEL CENTER
	oSayGrp7:SetCSS( POSCSS (GetClassName(oSayGrp7), CSS_BTN_FOCAL ))
	@ 019, 005 SAY oSayGrp7 PROMPT "" SIZE 001, 351 OF oPanel7 COLORS 0, 16777215 PIXEL CENTER
	oSayGrp7:SetCSS( POSCSS (GetClassName(oSayGrp7), CSS_BTN_FOCAL ))

	@ 021, 010 SAY oSay15 PROMPT "SALDO (R$)" SIZE 070, 008 OF oPanel7 COLORS 0, 16777215 PIXEL
	oSay15:SetCSS( POSCSS (GetClassName(oSay15), CSS_LABEL_FOCAL ))
	@ 019, 095 MSGET oGet15 VAR nGet15 SIZE 050, 013 OF oPanel7 PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL READONLY
	oGet15:SetCSS( POSCSS (GetClassName(oGet15), CSS_GET_NORMAL ))

	@ 036, 010 SAY oSay16 PROMPT "Seguro (-)" SIZE 070, 008 OF oPanel7 COLORS 0, 16777215 PIXEL
	oSay16:SetCSS( POSCSS (GetClassName(oSay16), CSS_LABEL_FOCAL ))
	@ 034, 095 MSGET oGet16 VAR nGet16 SIZE 050, 013 OF oPanel7 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL
	oGet16:SetCSS( POSCSS (GetClassName(oGet16), CSS_GET_NORMAL ))

	@ 051, 010 SAY oSay17 PROMPT "Imp. Renda Fonte (-)" SIZE 070, 008 OF oPanel7 COLORS 0, 16777215 PIXEL
	oSay17:SetCSS( POSCSS (GetClassName(oSay17), CSS_LABEL_FOCAL ))
	@ 049, 095 MSGET oGet17 VAR nGet17 SIZE 050, 013 OF oPanel7 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL
	oGet17:SetCSS( POSCSS (GetClassName(oGet17), CSS_GET_NORMAL ))

	@ 066, 010 SAY oSay18 PROMPT "INSS (-)" SIZE 070, 008 OF oPanel7 COLORS 0, 16777215 PIXEL
	oSay18:SetCSS( POSCSS (GetClassName(oSay18), CSS_LABEL_FOCAL ))
	@ 064, 095 MSGET oGet18 VAR nGet18 SIZE 050, 013 OF oPanel7 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL
	oGet18:SetCSS( POSCSS (GetClassName(oGet18), CSS_GET_NORMAL ))

	@ 081, 010 SAY oSay19 PROMPT "SEST/SENAT (-)" SIZE 070, 008 OF oPanel7 COLORS 0, 16777215 PIXEL
	oSay19:SetCSS( POSCSS (GetClassName(oSay19), CSS_LABEL_FOCAL ))
	@ 079, 095 MSGET oGet19 VAR nGet19 SIZE 050, 013 OF oPanel7 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL
	oGet19:SetCSS( POSCSS (GetClassName(oGet19), CSS_GET_NORMAL ))

	@ 096, 010 SAY oSay20 PROMPT "Adiantamento (-)" SIZE 070, 008 OF oPanel7 COLORS 0, 16777215 PIXEL
	oSay20:SetCSS( POSCSS (GetClassName(oSay20), CSS_LABEL_FOCAL ))
	@ 094, 095 MSGET oGet20 VAR nGet20 SIZE 050, 013 OF oPanel7 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL
	oGet20:SetCSS( POSCSS (GetClassName(oGet20), CSS_GET_NORMAL ))

	@ 111, 010 SAY oSay21 PROMPT "Falta de mercad. (-)" SIZE 070, 008 OF oPanel7 COLORS 0, 16777215 PIXEL
	oSay21:SetCSS( POSCSS (GetClassName(oSay21), CSS_LABEL_FOCAL ))
	@ 109, 095 MSGET oGet21 VAR nGet21 SIZE 050, 013 OF oPanel7 PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL READONLY
	oGet21:SetCSS( POSCSS (GetClassName(oGet21), CSS_GET_NORMAL ))

	@ 126, 010 SAY oSay22 PROMPT "Estadia (-)" SIZE 070, 008 OF oPanel7 COLORS 0, 16777215 PIXEL
	oSay22:SetCSS( POSCSS (GetClassName(oSay22), CSS_LABEL_FOCAL ))
	@ 124, 095 MSGET oGet22 VAR nGet22 SIZE 050, 013 OF oPanel7 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL
	oGet22:SetCSS( POSCSS (GetClassName(oGet22), CSS_GET_NORMAL ))

	@ 141, 010 SAY oSay23 PROMPT "Outros descontos (-)" SIZE 070, 008 OF oPanel7 COLORS 0, 16777215 PIXEL
	oSay23:SetCSS( POSCSS (GetClassName(oSay23), CSS_LABEL_FOCAL ))
	@ 139, 095 MSGET oGet23 VAR nGet23 SIZE 050, 013 OF oPanel7 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL
	oGet23:SetCSS( POSCSS (GetClassName(oGet23), CSS_GET_NORMAL ))

	@ 156, 010 SAY oSay24 PROMPT "Pedágio (+/-)" SIZE 070, 008 OF oPanel7 COLORS 0, 16777215 PIXEL
	oSay24:SetCSS( POSCSS (GetClassName(oSay24), CSS_LABEL_FOCAL ))
	@ 154, 095 MSGET oGet24 VAR nGet24 SIZE 050, 013 OF oPanel7 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL
	oGet24:SetCSS( POSCSS (GetClassName(oGet24), CSS_GET_NORMAL ))

	@ 171, 010 SAY oSay25 PROMPT "Taxa administrat. (-)" SIZE 070, 008 OF oPanel7 COLORS 0, 16777215 PIXEL
	oSay25:SetCSS( POSCSS (GetClassName(oSay25), CSS_LABEL_FOCAL ))
	@ 169, 095 MSGET oGet25 VAR nGet25 SIZE 050, 013 OF oPanel7 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL
	oGet25:SetCSS( POSCSS (GetClassName(oGet25), CSS_GET_NORMAL ))

	@ 186, 010 SAY oSay26 PROMPT "Adiant.1 Comb. (-)" SIZE 070, 008 OF oPanel7 COLORS 0, 16777215 PIXEL
	oSay26:SetCSS( POSCSS (GetClassName(oSay26), CSS_LABEL_FOCAL ))
	@ 184, 095 MSGET oGet26 VAR nGet26 SIZE 050, 013 OF oPanel7 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL
	oGet26:SetCSS( POSCSS (GetClassName(oGet26), CSS_GET_NORMAL ))

	@ 201, 010 SAY oSay27 PROMPT "Adiant.2 Comb. (-)" SIZE 070, 008 OF oPanel7 COLORS 0, 16777215 PIXEL
	oSay27:SetCSS( POSCSS (GetClassName(oSay27), CSS_LABEL_FOCAL ))
	@ 199, 095 MSGET oGet27 VAR nGet27 SIZE 050, 013 OF oPanel7 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL
	oGet27:SetCSS( POSCSS (GetClassName(oGet27), CSS_GET_NORMAL ))

	@ 216, 010 SAY oSay28 PROMPT "Outros Desc. Mot. (-)" SIZE 070, 008 OF oPanel7 COLORS 0, 16777215 PIXEL
	oSay28:SetCSS( POSCSS (GetClassName(oSay28), CSS_LABEL_FOCAL ))
	@ 214, 095 MSGET oGet28 VAR nGet28 SIZE 050, 013 OF oPanel7 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL
	oGet28:SetCSS( POSCSS (GetClassName(oGet28), CSS_GET_NORMAL ))

	@ 231, 010 SAY oSay29 PROMPT "Desp. Adc. Mot. (-)" SIZE 070, 008 OF oPanel7 COLORS 0, 16777215 PIXEL
	oSay29:SetCSS( POSCSS (GetClassName(oSay29), CSS_LABEL_FOCAL ))
	@ 229, 095 MSGET oGet29 VAR nGet29 SIZE 050, 013 OF oPanel7 VALID CalcSaldo() PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL
	oGet29:SetCSS( POSCSS (GetClassName(oGet29), CSS_GET_NORMAL ))

	@ 253, 010 SAY oSayGrp7 PROMPT "" SIZE (oPanel7:nWidth/2)-017, 001 OF oPanel7 COLORS 0, 16777215 PIXEL CENTER
	oSayGrp7:SetCSS( POSCSS (GetClassName(oSayGrp7), CSS_BTN_FOCAL ))

	@ 258, 010 SAY oSay30 PROMPT "SALDO FINAL (R$)" SIZE 070, 008 OF oPanel7 COLORS 0, 16777215 PIXEL
	oSay30:SetCSS( POSCSS (GetClassName(oSay30), CSS_LABEL_FOCAL ))
	@ 256, 095 MSGET oGet30 VAR nGet30 SIZE 050, 013 OF oPanel7 PICTURE "@E 999,999.99" COLORS 0, 16777215 PIXEL READONLY
	oGet30:SetCSS( POSCSS (GetClassName(oGet30), CSS_GET_NORMAL ))

	@ 273, 010 SAY oSayGrp7 PROMPT "" SIZE (oPanel7:nWidth/2)-017, 001 OF oPanel7 COLORS 0, 16777215 PIXEL CENTER
	oSayGrp7:SetCSS( POSCSS (GetClassName(oSayGrp7), CSS_BTN_FOCAL ))

	// -- BOTOES ---
	//@ 280, 356 BUTTON oButton3 PROMPT "Confirmar" SIZE 037, 012 OF oPanelCTF PIXEL ACTION (oCFVlrRec:cText:=nGet30, oDlgSldCtf:End())
	//oButton3:SetCSS( POSCSS (GetClassName(oButton3), CSS_BTN_FOCAL ))
	//@ 280, 311 BUTTON oButton1 PROMPT "Limpar" SIZE 037, 012 OF oPanelCTF PIXEL ACTION LimpaTela()
	//oButton1:SetCSS( POSCSS (GetClassName(oButton1), CSS_BTN_NORMAL ))
	//@ 280, 266 BUTTON oButton2 PROMPT "Imprimir" SIZE 037, 012 OF oPanelCTF PIXEL
	//oButton2:SetCSS( POSCSS (GetClassName(oButton2), CSS_BTN_NORMAL ))

	oBtn1 := TButton():New( nHeight-045,nWidth-080,"&Confirmar",oPanelCTF,{|| FazBkpDados(), oDlgSldCtf:End() },070,020,,,,.T.,,,,{|| .T.})
	oBtn1:SetCSS( POSCSS (GetClassName(oBtn1), CSS_BTN_FOCAL ))

	oBtn3 := TButton():New( nHeight-045,nWidth-230,"&Imprimir",oPanelCTF,{|| U_TRETR024() },070,020,,,,.T.,,,,{|| .T.})
	oBtn3:SetCSS( POSCSS (GetClassName(oBtn3), CSS_BTN_NORMAL ))

	oBtn2 := TButton():New( nHeight-045,nWidth-155,"&Limpar",oPanelCTF,{|| LimpaTela() },070,020,,,,.T.,,,,{|| .T.})
	oBtn2:SetCSS( POSCSS (GetClassName(oBtn2), CSS_BTN_NORMAL ))

	ResBkpDados()

	ACTIVATE MSDIALOG oDlgSldCtf CENTERED

	SetKey(VK_F3, {|| oCFVlrRec:cText:=U_TPDVA014(cCodCF,cLojCF) })

Return nGet30

/*/{Protheus.doc}
Faz calculo do saldo da carta frete
/*/
Static Function CalcSaldo(cCampo)
	Default cCampo := ReadVar()

	cCampo := UPPER(AllTrim(cCampo))

//Diferença de Peso
	If cCampo $ 'NGET1' .or. cCampo $ 'NGET2'
		nGet3 := nGet1 - nGet2
	ElseIf cCampo $ 'NGET3' .and. nGet1 > nGet3
		nGet2 := nGet1 - nGet3
	EndIf

//Cálculo da Tolerância
	If cCampo $ 'NGET4' .and. nGet1 > 0
		nGet5 := Round(nGet1*(nGet4/100),2)
	ElseIf cCampo $ 'NGET5' .and. nGet1 > 0
		nGet4 := (nGet5/nGet1)*100
	EndIf

//Critério da Quebra
	If (nGet5>=nGet3)
		cGet6 := "NÃO"
		nGet9 := 0
	Else
		cGet6 := "SIM"
	EndIf

//Cálculo da Quebra
	If (cCampo $ 'NGET9' .or. cCampo $ 'NRADMENU1')
		If nGet9 > 0
			nGet10 := nGet1
			nGet11 := Round(nGet9/nGet1,2)
			If nRadMenu1 == 1 //"INTEGRAL"
				nGet12 := Round(nGet11 * nGet3,2)
			Else //"PARCIAL"
				nGet12 := Round(nGet11 * (nGet3 - nGet5),2)
			EndIf
			nGet21 := nGet12
		EndIf
	EndIf

	If nGet9 <= 0
		nGet10 := 0
		nGet11 := 0
		nGet12 := 0
		nGet21 := 0
	EndIf

//Cálculo do Frete sem Descontos
	nGet7 := iif(nGet1<nGet2,nGet1,nGet2)

//SALDO (R$)
	nGet15 := Round((nGet8 * nGet7) / 1000,2)

//SALDO FINAL (R$)
	nGet30 := nGet15 - nGet16 - nGet17 - nGet18 - nGet19 - nGet20 - nGet21 - nGet22 - nGet23 + nGet24 - nGet25 - nGet26 - nGet27 - nGet28 - nGet29
	nGet30 := Round(nGet30,2)

	RefreshTela()
Return .T.

/*/{Protheus.doc}
Limpa a tela
/*/
Static Function LimpaTela()
	Local nX := 0
	For nX := 1 to 30
		&("nGet"+cValToChar(nX)) := 0
	Next nX
	cGet6 := "NÃO"
	nRadMenu1 := 1
	cGet14 := SPACE(120)
	U_TPDVA14A()
	RefreshTela()
Return

/*/{Protheus.doc}
Atualiza campos
/*/
Static Function RefreshTela()
	Local nX := 0
	For nX := 1 to 30
		&("oGet"+cValToChar(nX)+":Refresh()")
	Next nX
	oRadMenu1:Refresh()
Return

/*/{Protheus.doc}
Faz bakcup da ultima carta frete
/*/
Static Function FazBkpDados()
	Local nX := 0
	aBkpCF := {}
	For nX := 1 to 30
		aadd(aBkpCF,&("oGet"+cValToChar(nX)+":cText"))
	Next nX
	aadd(aBkpCF,nRadMenu1)
Return

/*/{Protheus.doc}
Restaura bakcup da ultima carta frete
/*/
Static Function ResBkpDados()
	Local nX := 0
	If Len(aBkpCF) > 30
		For nX := 1 to 30
			&("oGet"+cValToChar(nX)+":cText") := aBkpCF[nX]
		Next nX
		nRadMenu1 := aBkpCF[31]
	EndIf
Return

/*/{Protheus.doc}
Limpa array do bakcup da ultima carta frete
/*/
User Function TPDVA14A()
	aBkpCF := {}
Return

