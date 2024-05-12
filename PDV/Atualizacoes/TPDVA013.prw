#include 'poscss.ch'
#include "TOTVS.CH"
#include 'stpos.ch'
#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TOPCONN.CH'
#include "rwmake.ch"
#INCLUDE "tbiconn.ch"

#DEFINE CSS_MYLIST "TCBrowse{ font:  12px; background-color: #FFFFFF; color: #000000; margin: 0px; }" //border: none;

Static cLastLoad := ""

/*/{Protheus.doc} TPDVA013
Consulta Limites de Créditos de Cliente e Grupo na retaguarda.

@author Danilo Brito
@since 07/12/2017
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TPDVA013(lCliSelected)

    Local aArea := GetArea()
    Local aAreaSA1 := SA1->(GetArea())
    Local cCliSel := STDGPBasket("SL1","L1_CLIENTE")
	Local cLojSel := STDGPBasket("SL1","L1_LOJA")
	Local cCliPad := SuperGetMv("MV_CLIPAD") // Cliente padrao
	Local cLojaPad := SuperGetMV("MV_LOJAPAD") // Loja padrao

    //componentes visuais
    Local oPnlMain
    Local oPanelLim
    Local oPnlCad
    Local oPnlNeg

    Default lCliSelected := .F.
    
    Private oCodCli
    Private cCodCli := Space(TamSx3("L1_CLIENTE")[1])
    Private oLojCli
    Private cLojCli := Space(TamSx3("L1_LOJA")[1])
    Private oCgcCli
    Private cCgcCli := Space(TamSx3("A1_CGC")[1])
    Private oNomCli
    Private cNomCli := Space(TamSx3("A1_NOME")[1])

    Private oTFolder

    Private oNmFant
    Private cNmFant := ""
    Private oEndCli
    Private cEndCli := ""
    Private oTpPessoa
    Private cTpPessoa := ""
    Private oRgInsc
    Private cRgInsc := ""
    Private oDtCad
    Private cDtCad := ""
    Private oTpDoc
    Private cTpDoc := ""
    Private oEmitCheq
    Private cEmitCheq := ""
    Private oEmitCarta
    Private cEmitCarta := ""
    Private oObrPlaca
    Private cObrPlaca := ""
    Private oObrPlacAm
    Private cObrPlacAm := ""
    Private oObrKM
    Private cObrKM := ""
    Private oObrMotor
    Private cObrMotor := ""
    Private oGrupoCli
    Private cGrupoCli := ""
    Private oClasseFat
    Private cClasseFat := ""
    Private oListPlacas
    Private aListPlacas := {}

    Private oCSayLimV
    Private nCSayLimV := 0
    Private oCSayUsadV
    Private nCSayUsadV := 0
    Private oCSaySaldV
    Private nCSaySaldV := 0
    Private oCProgBarV
    Private oCSayBarV
    Private nCPercBarV := 0
    Private oCSayBlqV
    Private cCSayBlqV := "NÃO"

    Private oGSayLimV
    Private nGSayLimV := 0
    Private oGSayUsadV
    Private nGSayUsadV := 0
    Private oGSaySaldV
    Private nGSaySaldV := 0
    Private oGProgBarV 
    Private oGSayBarV 
    Private nGPercBarV := 0
    Private oGSayBlqV
    Private cGSayBlqV := "NÃO"

    Private oCSayLimS
    Private nCSayLimS := 0
    Private oCSayUsadS
    Private nCSayUsadS := 0
    Private oCSaySaldS
    Private nCSaySaldS := 0
    Private oCProgBarS
    Private oCSayBarS
    Private nCPercBarS := 0
    Private oCSayBlqS
    Private cCSayBlqS := "NÃO"

    Private oGSayLimS
    Private nGSayLimS := 0
    Private oGSayUsadS
    Private nGSayUsadS := 0
    Private oGSaySaldS
    Private nGSaySaldS := 0
    Private oGProgBarS
    Private oGSayBarS
    Private nGPercBarS := 0
    Private oGSayBlqS
    Private cGSayBlqS := "NÃO"

    Private nPxProgBr := 0

    Private oListNegPag
    Private aListNegPag := {}
    Private oListPrcNeg
    Private aListPrcNeg := {}

    cLastLoad := ""
    
    if lCliSelected 
        //verifico se ja foi selecionado o cliente
        If Empty(cCliSel) .OR. cCliPad+cLojaPad == cCliSel+cLojSel //se nao selecionou, ou é o cliente padrao
            MsgInfo("Cliente Padrão! Não há controle de limite para esse cliente!","")
            Return
        Endif

        cCodCli := cCliSel
        cLojCli := cLojSel

        //VldCliente("ONLOAD", .F.)

    endif

    //limpa as tecla atalho
    U_UKeyCtr() 

    DEFINE MSDIALOG oDlgLimites TITLE "" FROM 000,000 TO 600,800 PIXEL STYLE nOr(WS_VISIBLE, WS_POPUP)

        nWidth  := (oDlgLimites:nWidth/2)
        nHeight := (oDlgLimites:nHeight/2)

        @ 000, 000 MSPANEL oPnlMain SIZE nWidth, nHeight OF oDlgLimites
        oPnlMain:SetCSS( "TPanel{border: 2px solid #999999; background-color: #f4f4f4;}" )

        @ 000, 000 MSPANEL oPnlTop SIZE nWidth, 017 OF oPnlMain
        oPnlTop:SetCSS( POSCSS (GetClassName(oPnlTop), CSS_BAR_TOP ))
        @ 004, 005 SAY oSay1 PROMPT " Consulta Dados do Cliente " SIZE 150, 015 OF oPnlTop COLORS 0, 16777215 PIXEL
        oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BREADCUMB ))
        oClose := TBtnBmp2():New( 002,oDlgLimites:nWidth-25,20,30,'FWSKIN_DELETE_ICO',,,,{|| oDlgLimites:End() },oPnlTop,,,.T. )
        oClose:SetCss("TBtnBmp2{border: none;background-color: none;}")

        @ 025, 005 SAY oSay3 PROMPT "Código" SIZE 050, 008 OF oPnlMain COLORS 0, 16777215 PIXEL
        oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
        oCodCli := TGet():New( 035, 005, {|u| iif( PCount()==0,cCodCli,cCodCli:=u) },oPnlMain, 060, 013, "@!",{|| VldCliente() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cCodCli",,,,.T.,.F.)
        oCodCli:SetCSS( POSCSS (GetClassName(oCodCli), CSS_GET_NORMAL ))

        @ 025, 070 SAY oSay4 PROMPT "Loja" SIZE 050, 008 OF oPnlMain COLORS 0, 16777215 PIXEL
        oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
        oLojCli := TGet():New( 035, 070, {|u| iif( PCount()==0,cLojCli,cLojCli:=u) },oPnlMain, 025, 013, "@!",{|| VldCliente() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cLojCli",,,,.T.,.F.)
        oLojCli:SetCSS( POSCSS (GetClassName(oLojCli), CSS_GET_NORMAL ))

        @ 025, 100 SAY oSay2 PROMPT "CPF/CNPJ" SIZE 060, 008 OF oPnlMain COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))
        oCgcCli := TGet():New( 035, 100, {|u| iif( PCount()==0,cCgcCli,cCgcCli:=u) },oPnlMain, 080, 013, "@!",{|| VldCliente() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cCgcCli",,,,.T.,.F.)
        oCgcCli:SetCSS( POSCSS (GetClassName(oCgcCli), CSS_GET_NORMAL ))

        @ 025, 185 SAY oSay5 PROMPT "Nome" SIZE 070, 008 OF oPnlMain COLORS 0, 16777215 PIXEL
        oSay5:SetCSS( POSCSS (GetClassName(oSay5), CSS_LABEL_FOCAL ))
        oNomCli := TGet():New( 035, 185,{|u| iif( PCount()==0,cNomCli,cNomCli:=u)},oPnlMain, nWidth-190, 013, "@!",{|| .T. },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"cNomCli",,,,.T.,.F.)
        oNomCli:SetCSS( POSCSS (GetClassName(oNomCli), CSS_GET_NORMAL ))
        oNomCli:lCanGotFocus := .F.

        TSearchF3():New(oCodCli,400,250,"SA1","A1_COD",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'",{{"A1_NOME","A1_EST","A1_MUN"},{"A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,0,,{{oLojCli,"A1_LOJA"},{oCgcCli,"A1_CGC"},{oNomCli,"A1_NOME"}})
        TSearchF3():New(oCgcCli,400,250,"SA1","A1_CGC",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'",{{"A1_NOME","A1_EST","A1_MUN"},{"A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,0,,{{oCodCli,"A1_COD"},{oLojCli,"A1_LOJA"},{oNomCli,"A1_NOME"}})

        oBtn1 := TButton():New( 052,nWidth-080,"Atualizar",oPnlMain,{|| VldCliente("ONLOAD") },070,012,,,,.T.,,,,{|| .T.})
        oBtn1:SetCSS( POSCSS (GetClassName(oBtn1), CSS_BTN_FOCAL ))

        oTFolder := TFolder():New( 065, 005, {"Cadastro","Limites de Credito","Negociações"},,oPnlMain,,,,.T.,,nWidth-012,nHeight-100 )
        oPnlCad := oTFolder:aDialogs[1]
        oPnlCad:SetCSS( "TFolderPage{border: none; background-color: #F4F4F4;}" )
        oPanelLim := oTFolder:aDialogs[2]
        oPanelLim:SetCSS( "TFolderPage{border: none; background-color: #F4F4F4;}") 
        oPnlNeg := oTFolder:aDialogs[3]
        oPnlNeg:SetCSS( "TFolderPage{border: none; background-color: #F4F4F4;}") 

        //###########################  PAINEL CADASTRAIS ##############################
        
        @ 003, 005 SAY oSay2 PROMPT "Nome fantasia" SIZE 100, 008 OF oPnlCad COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_NORMAL ))
        @ 003, 070 SAY oNmFant VAR cNmFant SIZE nWidth-90, 008 OF oPnlCad COLOR 0, 16777215 PIXEL
	    oNmFant:SetCSS( POSCSS (GetClassName(oNmFant), CSS_LABEL_FOCAL ))

        @ 016, 005 SAY oSay2 PROMPT "Endereço" SIZE 100, 008 OF oPnlCad COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_NORMAL ))
        @ 016, 070 SAY oEndCli VAR cEndCli SIZE nWidth-90, 008 OF oPnlCad COLOR 0, 16777215 PIXEL
	    oEndCli:SetCSS( POSCSS (GetClassName(oEndCli), CSS_LABEL_FOCAL ))

        @ 029, 005 SAY oSay2 PROMPT "Tipo Pessoa" SIZE 100, 008 OF oPnlCad COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_NORMAL ))
        @ 029, 070 SAY oTpPessoa VAR cTpPessoa SIZE (nWidth/2)-90, 008 OF oPnlCad COLOR 0, 16777215 PIXEL
	    oTpPessoa:SetCSS( POSCSS (GetClassName(oTpPessoa), CSS_LABEL_FOCAL ))

        @ 029, (nWidth/2) SAY oSay2 PROMPT "RG / Inscr. Est." SIZE 100, 008 OF oPnlCad COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_NORMAL ))
        @ 029, (nWidth/2)+070 SAY oRgInsc VAR cRgInsc SIZE (nWidth/2)-90, 008 OF oPnlCad COLOR 0, 16777215 PIXEL
	    oRgInsc:SetCSS( POSCSS (GetClassName(oRgInsc), CSS_LABEL_FOCAL ))

        @ 042, 005 SAY oSay2 PROMPT "Data Cadastro" SIZE 100, 008 OF oPnlCad COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_NORMAL ))
        @ 042, 070 SAY oDtCad VAR cDtCad SIZE (nWidth/2)-90, 008 OF oPnlCad COLOR 0, 16777215 PIXEL
	    oDtCad:SetCSS( POSCSS (GetClassName(oDtCad), CSS_LABEL_FOCAL ))

        @ 042, (nWidth/2) SAY oSay2 PROMPT "Tipo Documento" SIZE 100, 008 OF oPnlCad COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_NORMAL ))
        @ 042, (nWidth/2)+070 SAY oTpDoc VAR cTpDoc SIZE (nWidth/2)-90, 008 OF oPnlCad COLOR 0, 16777215 PIXEL
	    oTpDoc:SetCSS( POSCSS (GetClassName(oTpDoc), CSS_LABEL_FOCAL ))

        @ 055, 005 SAY oSay2 PROMPT "Emitente Cheque?" SIZE 100, 008 OF oPnlCad COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_NORMAL ))
        @ 055, 070 SAY oEmitCheq VAR cEmitCheq SIZE (nWidth/2)-90, 008 OF oPnlCad COLOR 0, 16777215 PIXEL
	    oEmitCheq:SetCSS( POSCSS (GetClassName(oEmitCheq), CSS_LABEL_FOCAL ))

        @ 055, (nWidth/2) SAY oSay2 PROMPT "Emit. Carta Frete?" SIZE 100, 008 OF oPnlCad COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_NORMAL ))
        @ 055, (nWidth/2)+070 SAY oEmitCarta VAR cEmitCarta SIZE (nWidth/2)-90, 008 OF oPnlCad COLOR 0, 16777215 PIXEL
	    oEmitCarta:SetCSS( POSCSS (GetClassName(oEmitCarta), CSS_LABEL_FOCAL ))

        @ 068, 005 SAY oSay2 PROMPT "Obr. Inf. Placa?" SIZE 100, 008 OF oPnlCad COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_NORMAL ))
        @ 068, 070 SAY oObrPlaca VAR cObrPlaca SIZE (nWidth/2)-90, 008 OF oPnlCad COLOR 0, 16777215 PIXEL
	    oObrPlaca:SetCSS( POSCSS (GetClassName(oObrPlaca), CSS_LABEL_FOCAL ))

        @ 068, (nWidth/2) SAY oSay2 PROMPT "Obr. Amarração Placa?" SIZE 100, 008 OF oPnlCad COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_NORMAL ))
        @ 068, (nWidth/2)+070 SAY oObrPlacAm VAR cObrPlacAm SIZE (nWidth/2)-90, 008 OF oPnlCad COLOR 0, 16777215 PIXEL
	    oObrPlacAm:SetCSS( POSCSS (GetClassName(oObrPlacAm), CSS_LABEL_FOCAL ))

        @ 081, 005 SAY oSay2 PROMPT "Obriga Inf. KM?" SIZE 100, 008 OF oPnlCad COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_NORMAL ))
        @ 081, 070 SAY oObrKM VAR cObrKM SIZE (nWidth/2)-90, 008 OF oPnlCad COLOR 0, 16777215 PIXEL
	    oObrKM:SetCSS( POSCSS (GetClassName(oObrKM), CSS_LABEL_FOCAL ))

        @ 081, (nWidth/2) SAY oSay2 PROMPT "Obriga Inf. Motorista?" SIZE 100, 008 OF oPnlCad COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_NORMAL ))
        @ 081, (nWidth/2)+070 SAY oObrMotor VAR cObrMotor SIZE (nWidth/2)-90, 008 OF oPnlCad COLOR 0, 16777215 PIXEL
	    oObrMotor:SetCSS( POSCSS (GetClassName(oObrMotor), CSS_LABEL_FOCAL ))
        
        @ 094, 005 SAY oSay2 PROMPT "Grupo Cliente" SIZE 100, 008 OF oPnlCad COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_NORMAL ))
        @ 094, 070 SAY oGrupoCli VAR cGrupoCli SIZE (nWidth/2)-90, 008 OF oPnlCad COLOR 0, 16777215 PIXEL
	    oGrupoCli:SetCSS( POSCSS (GetClassName(oGrupoCli), CSS_LABEL_FOCAL ))

        @ 094, (nWidth/2) SAY oSay2 PROMPT "Classe Faturamento?" SIZE 100, 008 OF oPnlCad COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_NORMAL ))
        @ 094, (nWidth/2)+070 SAY oClasseFat VAR cClasseFat SIZE (nWidth/2)-90, 008 OF oPnlCad COLOR 0, 16777215 PIXEL
	    oClasseFat:SetCSS( POSCSS (GetClassName(oClasseFat), CSS_LABEL_FOCAL ))

        @ 115, 005 SAY oSay2 PROMPT ("---  Placas Amarradas  "+Replicate("-",142)) SIZE nWidth-10, 008 OF oPnlCad COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))
        
        @ 125, 005 LISTBOX oListPlacas VAR nListLogs FIELDS HEADER "Placa","Descrição","Cliente","Grupo" SIZE nWidth-25, 060 OF oPnlCad COLORS 0, 16777215 PIXEL NOSCROLL
        aListPlacas := Retbline(oListPlacas, {} )
        oListPlacas:SetArray(aListPlacas)
        oListPlacas:bLine := {|| Retbline(oListPlacas, aListPlacas ) }
        oListPlacas:aColSizes := {100, 150, 50, 50}
        oListPlacas:SetCSS( CSS_MYLIST ) 
        oListPlacas:lHScroll   := .F. // NoScroll

        //###########################  PAINEL DE LIMITES DE VENDA ##############################

        @ 002, 001 SAY oSay1 PROMPT "LIMITES DE VENDA" SIZE nWidth-015, 015 OF oPanelLim COLORS 0, 16777215 PIXEL CENTER
	    oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BTN_FOCAL ))

        @ 019, 002 SAY oSay1 PROMPT "" SIZE 001, 070 OF oPanelLim COLORS 0, 16777215 PIXEL CENTER
	    oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BTN_FOCAL ))
        @ 019, 005 SAY oSay6 PROMPT "CLIENTE" SIZE 100, 011 OF oPanelLim COLORS 0, 16777215 PIXEL
        oSay6:SetCSS( POSCSS (GetClassName(oSay6), CSS_BREADCUMB ))

        @ 037, 005 SAY oSay2 PROMPT "Bloqueado para vendas?" SIZE 100, 008 OF oPanelLim COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

        @ 037, (nWidth/2)-125 SAY oCSayBlqV VAR cCSayBlqV SIZE 100, 008 OF oPanelLim RIGHT COLOR 0, 16777215 PIXEL
	    oCSayBlqV:SetCSS( POSCSS (GetClassName(oCSayBlqV), CSS_LABEL_FOCAL ))

        @ 047, 005 SAY oSay2 PROMPT "Limite de Crédito" SIZE 100, 008 OF oPanelLim COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

        @ 047, (nWidth/2)-125 SAY oCSayLimV VAR AllTrim(Transform(nCSayLimV,"@E 999,999,999.99")) SIZE 100, 008 OF oPanelLim RIGHT COLOR 0, 16777215 PIXEL
	    oCSayLimV:SetCSS( POSCSS (GetClassName(oCSayLimV), CSS_LABEL_FOCAL ))

        @ 057, 005 SAY oSay2 PROMPT "Valor Utilizado" SIZE 100, 008 OF oPanelLim COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

        @ 057, (nWidth/2)-125 SAY oCSayUsadV VAR AllTrim(Transform(nCSayUsadV,"@E 999,999,999.99")) SIZE 100, 008 OF oPanelLim RIGHT COLOR 0, 16777215 PIXEL
	    oCSayUsadV:SetCSS( POSCSS (GetClassName(oCSayUsadV), CSS_LABEL_FOCAL ))

        @ 067, 005 SAY oSay2 PROMPT "Saldo do Limite" SIZE 100, 008 OF oPanelLim COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

        @ 067, (nWidth/2)-125 SAY oCSaySaldV VAR AllTrim(Transform(nCSaySaldV,"@E 999,999,999.99")) SIZE 100, 008 OF oPanelLim RIGHT COLOR 0, 16777215 PIXEL
	    oCSaySaldV:SetCSS( POSCSS (GetClassName(oCSaySaldV), CSS_LABEL_FOCAL ))

        
        nPxProgBr := (nWidth/2)-75
        //progress bar 
        @ 079, 007 SAY oSay2 PROMPT "" SIZE nPxProgBr,010 OF oPanelLim COLORS 0, 16777215 PIXEL
	    oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_GET_NORMAL ))
        @ 081, 009 SAY oCProgBarV PROMPT "" SIZE 000, 006 OF oPanelLim COLORS 0, 16777215 PIXEL CENTER
	    oCProgBarV:SetCSS( POSCSS (GetClassName(oCProgBarV), CSS_BTN_FOCAL ))
        @ 079, (nWidth/2)-85 SAY oCSayBarV PROMPT (cValToChar(nCPercBarV)+"% utilizado") SIZE 090, 010 OF oPanelLim COLORS 0, 16777215 PIXEL CENTER
        oCSayBarV:SetCSS( POSCSS (GetClassName(oCSayBarV), CSS_LABEL_NORMAL))


        @ 019, (nWidth/2)-3 SAY oSay1 PROMPT "" SIZE 001, 070 OF oPanelLim COLORS 0, 16777215 PIXEL CENTER
	    oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BTN_FOCAL ))
        @ 019, (nWidth/2) SAY oSay6 PROMPT "GRUPO DE CLIENTE" SIZE 100, 011 OF oPanelLim COLORS 0, 16777215 PIXEL
        oSay6:SetCSS( POSCSS (GetClassName(oSay6), CSS_BREADCUMB ))

        @ 037, (nWidth/2) SAY oSay2 PROMPT "Bloqueado para vendas?" SIZE 100, 008 OF oPanelLim COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

        @ 037, nWidth-130 SAY oGSayBlqV VAR cGSayBlqV SIZE 100, 008 OF oPanelLim RIGHT COLOR 0, 16777215 PIXEL
	    oGSayBlqV:SetCSS( POSCSS (GetClassName(oGSayBlqV), CSS_LABEL_FOCAL ))

        @ 047, (nWidth/2) SAY oSay2 PROMPT "Limite de Crédito" SIZE 100, 008 OF oPanelLim COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

        @ 047, nWidth-130 SAY oGSayLimV VAR AllTrim(Transform(nGSayLimV,"@E 999,999,999.99")) SIZE 100, 008 OF oPanelLim RIGHT COLOR 0, 16777215 PIXEL
	    oGSayLimV:SetCSS( POSCSS (GetClassName(oGSayLimV), CSS_LABEL_FOCAL ))

        @ 057, (nWidth/2) SAY oSay2 PROMPT "Valor Utilizado" SIZE 100, 008 OF oPanelLim COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

        @ 057, nWidth-130 SAY oGSayUsadV VAR AllTrim(Transform(nGSayUsadV,"@E 999,999,999.99")) SIZE 100, 008 OF oPanelLim RIGHT COLOR 0, 16777215 PIXEL
	    oGSayUsadV:SetCSS( POSCSS (GetClassName(oGSayUsadV), CSS_LABEL_FOCAL ))

        @ 067, (nWidth/2) SAY oSay2 PROMPT "Saldo do Limite" SIZE 100, 008 OF oPanelLim COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

        @ 067, nWidth-130 SAY oGSaySaldV VAR AllTrim(Transform(nGSaySaldV,"@E 999,999,999.99")) SIZE 100, 008 OF oPanelLim RIGHT COLOR 0, 16777215 PIXEL
	    oGSaySaldV:SetCSS( POSCSS (GetClassName(oGSaySaldV), CSS_LABEL_FOCAL ))

        //progress bar 
        @ 079, (nWidth/2)+2 SAY oSay2 PROMPT "" SIZE nPxProgBr,010 OF oPanelLim COLORS 0, 16777215 PIXEL
	    oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_GET_NORMAL ))
        @ 081, (nWidth/2)+4 SAY oGProgBarV PROMPT "" SIZE 000, 006 OF oPanelLim COLORS 0, 16777215 PIXEL CENTER
	    oGProgBarV:SetCSS( POSCSS (GetClassName(oGProgBarV), CSS_BTN_FOCAL ))
        @ 079, nWidth-90 SAY oGSayBarV PROMPT (cValToChar(nGPercBarV)+"% utilizado") SIZE 090, 010 OF oPanelLim COLORS 0, 16777215 PIXEL CENTER
        oGSayBarV:SetCSS( POSCSS (GetClassName(oGSayBarV), CSS_LABEL_NORMAL))


        //###########################  PAINEL DE LIMITES DE SAQUE ##############################

        @ 099, 001 SAY oSay1 PROMPT "LIMITES DE SAQUE" SIZE nWidth-015, 015 OF oPanelLim COLORS 0, 16777215 PIXEL CENTER
	    oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BTN_FOCAL ))

        @ 116, 002 SAY oSay1 PROMPT "" SIZE 001, 070 OF oPanelLim COLORS 0, 16777215 PIXEL CENTER
	    oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BTN_FOCAL ))
        @ 116, 005 SAY oSay6 PROMPT "CLIENTE" SIZE 100, 011 OF oPanelLim COLORS 0, 16777215 PIXEL
        oSay6:SetCSS( POSCSS (GetClassName(oSay6), CSS_BREADCUMB ))

        @ 133, 005 SAY oSay2 PROMPT "Bloqueado para saque?" SIZE 100, 008 OF oPanelLim COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

        @ 133, (nWidth/2)-125 SAY oCSayBlqS VAR cCSayBlqS SIZE 100, 008 OF oPanelLim RIGHT COLOR 0, 16777215 PIXEL
	    oCSayBlqS:SetCSS( POSCSS (GetClassName(oCSayBlqS), CSS_LABEL_FOCAL ))

        @ 143, 005 SAY oSay2 PROMPT "Limite de Crédito" SIZE 100, 008 OF oPanelLim COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

        @ 143, (nWidth/2)-125 SAY oCSayLimS VAR AllTrim(Transform(nCSayLimS,"@E 999,999,999.99")) SIZE 100, 008 OF oPanelLim RIGHT COLOR 0, 16777215 PIXEL
	    oCSayLimS:SetCSS( POSCSS (GetClassName(oCSayLimS), CSS_LABEL_FOCAL ))

        @ 153, 005 SAY oSay2 PROMPT "Valor Utilizado" SIZE 100, 008 OF oPanelLim COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

        @ 153, (nWidth/2)-125 SAY oCSayUsadS VAR AllTrim(Transform(nCSayUsadS,"@E 999,999,999.99")) SIZE 100, 008 OF oPanelLim RIGHT COLOR 0, 16777215 PIXEL
	    oCSayUsadS:SetCSS( POSCSS (GetClassName(oCSayUsadS), CSS_LABEL_FOCAL ))

        @ 163, 005 SAY oSay2 PROMPT "Saldo do Limite" SIZE 100, 008 OF oPanelLim COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

        @ 163, (nWidth/2)-125 SAY oCSaySaldS VAR AllTrim(Transform(nCSaySaldS,"@E 999,999,999.99")) SIZE 100, 008 OF oPanelLim RIGHT COLOR 0, 16777215 PIXEL
	    oCSaySaldS:SetCSS( POSCSS (GetClassName(oCSaySaldS), CSS_LABEL_FOCAL ))

        //progress bar 
        @ 175, 007 SAY oSay2 PROMPT "" SIZE nPxProgBr,010 OF oPanelLim COLORS 0, 16777215 PIXEL
	    oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_GET_NORMAL ))
        @ 177, 009 SAY oCProgBarS PROMPT "" SIZE 000, 006 OF oPanelLim COLORS 0, 16777215 PIXEL CENTER
	    oCProgBarS:SetCSS( POSCSS (GetClassName(oCProgBarS), CSS_BTN_FOCAL ))
        @ 175, (nWidth/2)-85 SAY oCSayBarS PROMPT (cValToChar(nCPercBarS)+"% utilizado") SIZE 090, 010 OF oPanelLim COLORS 0, 16777215 PIXEL CENTER
        oCSayBarS:SetCSS( POSCSS (GetClassName(oCSayBarS), CSS_LABEL_NORMAL))

        
        @ 116, (nWidth/2)-3 SAY oSay1 PROMPT "" SIZE 001, 070 OF oPanelLim COLORS 0, 16777215 PIXEL CENTER
	    oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BTN_FOCAL ))
        @ 116, (nWidth/2) SAY oSay6 PROMPT "GRUPO DE CLIENTE" SIZE 100, 011 OF oPanelLim COLORS 0, 16777215 PIXEL
        oSay6:SetCSS( POSCSS (GetClassName(oSay6), CSS_BREADCUMB ))

        @ 133, (nWidth/2) SAY oSay2 PROMPT "Bloqueado para saques?" SIZE 100, 008 OF oPanelLim COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

        @ 133, nWidth-130 SAY oGSayBlqS VAR cGSayBlqS SIZE 100, 008 OF oPanelLim RIGHT COLOR 0, 16777215 PIXEL
	    oGSayBlqS:SetCSS( POSCSS (GetClassName(oGSayBlqS), CSS_LABEL_FOCAL ))

        @ 143, (nWidth/2) SAY oSay2 PROMPT "Limite de Crédito" SIZE 100, 008 OF oPanelLim COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

        @ 143, nWidth-130 SAY oGSayLimS VAR AllTrim(Transform(nGSayLimS,"@E 999,999,999.99")) SIZE 100, 008 OF oPanelLim RIGHT COLOR 0, 16777215 PIXEL
	    oGSayLimS:SetCSS( POSCSS (GetClassName(oGSayLimS), CSS_LABEL_FOCAL ))

        @ 153, (nWidth/2) SAY oSay2 PROMPT "Valor Utilizado" SIZE 100, 008 OF oPanelLim COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

        @ 153, nWidth-130 SAY oGSayUsadS VAR AllTrim(Transform(nGSayUsadS,"@E 999,999,999.99")) SIZE 100, 008 OF oPanelLim RIGHT COLOR 0, 16777215 PIXEL
	    oGSayUsadS:SetCSS( POSCSS (GetClassName(oGSayUsadS), CSS_LABEL_FOCAL ))

        @ 163, (nWidth/2) SAY oSay2 PROMPT "Saldo do Limite" SIZE 100, 008 OF oPanelLim COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

        @ 163, nWidth-130 SAY oGSaySaldS VAR AllTrim(Transform(nGSaySaldS,"@E 999,999,999.99")) SIZE 100, 008 OF oPanelLim RIGHT COLOR 0, 16777215 PIXEL
	    oGSaySaldS:SetCSS( POSCSS (GetClassName(oGSaySaldS), CSS_LABEL_FOCAL ))

        //progress bar 
        @ 175, (nWidth/2)+2 SAY oSay2 PROMPT "" SIZE nPxProgBr,010 OF oPanelLim COLORS 0, 16777215 PIXEL
	    oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_GET_NORMAL ))
        @ 177, (nWidth/2)+4 SAY oGProgBarS PROMPT "" SIZE 000, 006 OF oPanelLim COLORS 0, 16777215 PIXEL CENTER
	    oGProgBarS:SetCSS( POSCSS (GetClassName(oGProgBarS), CSS_BTN_FOCAL ))
        @ 175, nWidth-90 SAY oGSayBarS PROMPT (cValToChar(nGPercBarS)+"% utilizado") SIZE 090, 010 OF oPanelLim COLORS 0, 16777215 PIXEL CENTER
        oGSayBarS:SetCSS( POSCSS (GetClassName(oGSayBarS), CSS_LABEL_NORMAL))

        //ajusto para ficar mais certo a barra de progresso
        nPxProgBr -= 4


        //###########################  PAINEL DE NEGOCIACOES ##############################

        @ 005, 005 SAY oSay2 PROMPT ("---  Negociações de Pagamento  "+Replicate("-",128)) SIZE nWidth-10, 008 OF oPnlNeg COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

        @ 015, 005 LISTBOX oListNegPag VAR nListLogs FIELDS HEADER "Forma","Condição","Descriçao","Tipo","Produto","Desc.Prod","Grupo Prod.","Desc.Grupo","Cliente","Grupo Cli." SIZE nWidth-25, 080 OF oPnlNeg COLORS 0, 16777215 PIXEL NOSCROLL
        aListNegPag := Retbline(oListNegPag, {} )
        oListNegPag:SetArray(aListNegPag)
        oListNegPag:bLine := {|| Retbline(oListNegPag, aListNegPag ) }
        oListNegPag:aColSizes := {30, 35, 70, 45, 65, 100, 45, 60, 50, 40}
        oListNegPag:SetCSS( CSS_MYLIST ) 

        @ 100, 005 SAY oSay2 PROMPT ("---  Preços Negociados Vigentes  "+Replicate("-",127)) SIZE nWidth-10, 008 OF oPnlNeg COLORS 0, 16777215 PIXEL
        oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))

        @ 110, 005 LISTBOX oListPrcNeg VAR nListLogs FIELDS HEADER "Produto","Desc.Prod","Preço Base","Desconto","Preço Neg.","Forma","Condição","Descriçao","Adm Fin","Desc.Adm.Fin.","Cliente","Grupo Cli." SIZE nWidth-25, 080 OF oPnlNeg COLORS 0, 16777215 PIXEL NOSCROLL
        aListPrcNeg := Retbline(oListPrcNeg, {} )
        oListPrcNeg:SetArray(aListPrcNeg)
        oListPrcNeg:bLine := {|| Retbline(oListPrcNeg, aListPrcNeg ) }
        oListPrcNeg:aColSizes := {65, 80, 50, 50, 50, 30, 35, 80, 30, 50, 50, 40}
        oListPrcNeg:SetCSS( CSS_MYLIST ) 


        oBtn1 := TButton():New( nHeight-030,nWidth-080,"Fechar",oPnlMain,{|| oDlgLimites:end() },070,020,,,,.T.,,,,{|| .T.})
        oBtn1:SetCSS( POSCSS (GetClassName(oBtn1), CSS_BTN_FOCAL ))

        oBtn2 := TButton():New( nHeight-030,nWidth-155,"Limpar",oPnlMain,{|| ClearCli() },070,020,,,,.T.,,,,{|| .T.})
        oBtn2:SetCSS( POSCSS (GetClassName(oBtn2), CSS_BTN_NORMAL ))

        if lCliSelected 
            RefreshDlg()
        endif

    ACTIVATE MSDIALOG oDlgLimites CENTERED ON INIT (iif(lCliSelected, VldCliente("ONLOAD", .T.), ))
    //restaura as teclas atalho
    U_UKeyCtr(.T.)

    RestArea(aAreaSA1)
    RestArea(aArea)

Return


//--------------------------------------------------------
// Validação e gatilho do cliente
//--------------------------------------------------------
Static Function VldCliente(cCampo, lRefresh)

    Local lRet := .T.
    Local aLimVenda, aLimSaque 
    Default cCampo := ReadVar()
    Default lRefresh := .T.

    If Upper(AllTrim(cCampo)) == 'CCGCCLI'
        If !Empty(cCgcCli)
            cNomCli := Posicione("SA1",3,xFilial("SA1")+cCgcCli,"A1_NOME") //A1_FILIAL+A1_CGC
            cCodCli := Posicione("SA1",3,xFilial("SA1")+cCgcCli,"A1_COD")
            cLojCli := Posicione("SA1",3,xFilial("SA1")+cCgcCli,"A1_LOJA")
        EndIf
    Else //If Upper(AllTrim(cCampo)) == 'CLOJCLI'
        If !Empty(cCodCli) .and. !Empty(cLojCli)
            cNomCli := Posicione("SA1",1,xFilial("SA1")+cCodCli+cLojCli,"A1_NOME") //A1_FILIAL+A1_COD+A1_LOJA
            cCgcCli := Posicione("SA1",1,xFilial("SA1")+cCodCli+cLojCli,"A1_CGC") 
        EndIf
    EndIf

    if empty(cCodCli)
        cNomCli := Space(TamSX3("A1_NOME")[1])
        cCodCli := Space(TamSX3("A1_COD")[1])
        cLojCli := Space(TamSX3("A1_LOJA")[1])
        cNmFant := ""
        cEndCli := ""
        cTpPessoa := ""
        cRgInsc := ""
        cDtCad := ""
        cTpDoc := ""
        cEmitCheq := ""
        cEmitCarta := ""
        cObrPlaca := ""
        cObrPlacAm := ""
        cObrKM := ""
        cObrMotor := ""
        cGrupoCli := ""
        cClasseFat := ""
        aListPlacas := Retbline(oListPlacas, {} )
        aListNegPag := Retbline(oListNegPag, {} )
        aListPrcNeg := Retbline(oListPrcNeg, {} )
    endif

    if !empty(cNomCli) .AND. (cLastLoad <> cCodCli+cLojCli+cCgcCli .OR. Upper(AllTrim(cCampo)) == "ONLOAD")

        cNmFant := Alltrim(SA1->A1_NREDUZ)
        cEndCli := Alltrim(SA1->A1_END) + ", " + Alltrim(SA1->A1_BAIRRO) + " - " + Alltrim(SA1->A1_MUN) + "/" + Alltrim(SA1->A1_EST) 
        cTpPessoa := iif(SA1->A1_PESSOA == 'F',"Física","Jurídica")
        cRgInsc := iif(SA1->A1_PESSOA == 'F',Alltrim(SA1->A1_PFISICA),Alltrim(SA1->A1_INSCR))
        cDtCad := DTOC(SA1->A1_DTCAD)
        cTpDoc := iif(SA1->A1_XTIPONF=="1","NF-e",iif(SA1->A1_XTIPONF=="2","NFC-e","Indefinido"))
        cEmitCheq := iif(SA1->A1_XEMCHQ=="S", "SIM", "NÃO")
        cEmitCarta := iif(SA1->A1_XEMICF=="S", "SIM", "NÃO")
        cObrPlaca := iif(SA1->A1_XFROTA=="S", "SIM", "NÃO")
        cObrPlacAm := iif(SA1->A1_XRESTRI=="S", "SIM", "NÃO")
        cObrKM := iif(SA1->A1_XODOMET=="S", "SIM", "NÃO")
        cObrMotor := iif(SA1->A1_XMOTOR=="S", "SIM", "NÃO")
        cGrupoCli := SA1->A1_GRPVEN
        if !empty(cGrupoCli)
            cGrupoCli += " - " + Alltrim(Posicione('ACY',1,xFilial('ACY')+SA1->A1_GRPVEN,'ACY_DESCRI'))
        endif
        cClasseFat := SA1->A1_XCLASSE
        if !empty(cClasseFat)
            cClasseFat += " - " + AllTrim(POSICIONE("UF6",1,XFILIAL('UF6')+SA1->A1_XCLASSE,"UF6_DESC"))
        endif
        aListPlacas := LoadPlacas(cCodCli, cLojCli, SA1->A1_GRPVEN)
        aListNegPag := LoadNegPag(cCodCli, cLojCli, SA1->A1_GRPVEN)
        aListPrcNeg := LoadPrcNeg(cCodCli, cLojCli, SA1->A1_GRPVEN)
        
        cLastLoad := cCodCli+cLojCli+cCgcCli

        if DoBuscaDados(cCodCli, cLojCli, @aLimVenda,@aLimSaque)

            //[01] [limite venda] ou [limite saque] UTILIZADO  do [Cliente] / [02] [limite venda] ou [limite saque] UTILIZADO  do [Grupo de Cliente]
            //[03] [limite venda] ou [limite saque] CADASTRADO do [Cliente] / [04] [limite venda] ou [limite saque] CADASTRADO do [Grupo de Cliente]
            //[05] [bloqueio venda] ou [bloqueio saque] do [Cliente]		/ [06] [bloqueio venda] ou [bloqueio saque] do [Grupo de Cliente]

            nCSayLimV := aLimVenda[1][03]
            nCSayUsadV := aLimVenda[1][01]
            nCSaySaldV := nCSayLimV - nCSayUsadV
            nCPercBarV := Round(nCSayUsadV / nCSayLimV * 100, 2)
            cCSayBlqV := iif(aLimVenda[1][05]=='1',"SIM","NÃO")
            
            nGSayLimV := aLimVenda[1][04]
            nGSayUsadV := aLimVenda[1][02]
            nGSaySaldV := nGSayLimV - nGSayUsadV
            nGPercBarV := Round(nGSayUsadV / nGSayLimV * 100, 2)
            cGSayBlqV := iif(aLimVenda[1][06]=='1',"SIM","NÃO")

            nCSayLimS := aLimSaque[1][03]
            nCSayUsadS := aLimSaque[1][01]
            nCSaySaldS := nCSayLimS - nCSayUsadS
            nCPercBarS := Round(nCSayUsadS / nCSayLimS * 100, 2)
            cCSayBlqS := iif(aLimSaque[1][05]=='1',"SIM","NÃO")

            nGSayLimS := aLimSaque[1][04]
            nGSayUsadS := aLimSaque[1][02]
            nGSaySaldS := nGSayLimS - nGSayUsadS
            nGPercBarS := Round(nGSayUsadS / nGSayLimS * 100, 2)
            cGSayBlqS := iif(aLimSaque[1][06]=='1',"SIM","NÃO")

        else
            MsgInfo("Não foi possível consultar os dados do cliente na retaguarda!", "Atenção")
            STFCleanMessage()
	        STFCleanInterfaceMessage()
        endif
    
    endif
    
    if lRefresh
        RefreshDlg()
    endif
	
Return lRet

//--------------------------------------------------------
// Limpar gets
//--------------------------------------------------------
Static Function ClearCli()

    cNomCli := Space(TamSX3("A1_NOME")[1])
    cCgcCli := Space(TamSX3("A1_CGC")[1])
    cCodCli := Space(TamSX3("A1_COD")[1])
    cLojCli := Space(TamSX3("A1_LOJA")[1])
    
    cNmFant := ""
    cEndCli := ""
    cTpPessoa := ""
    cRgInsc := ""
    cDtCad := ""
    cTpDoc := ""
    cEmitCheq := ""
    cEmitCarta := ""
    cObrPlaca := ""
    cObrPlacAm := ""
    cObrKM := ""
    cObrMotor := ""
    cGrupoCli := ""
    cClasseFat := ""
    aListPlacas := Retbline(oListPlacas, {} )
    aListNegPag := Retbline(oListNegPag, {} )
    aListPrcNeg := Retbline(oListPrcNeg, {} )

    cLastLoad := ""

    nCSayLimV := 0
    nCSayUsadV := 0
    nCSaySaldV := 0
    nCPercBarV := 0
    cCSayBlqV := "NÃO"
    
    nGSayLimV := 0
    nGSayUsadV := 0
    nGSaySaldV := 0
    nGPercBarV := 0
    cGSayBlqV := "NÃO"

    nCSayLimS := 0
    nCSayUsadS := 0
    nCSaySaldS := 0
    nCPercBarS := 0
    cCSayBlqS := "NÃO"

    nGSayLimS := 0
    nGSayUsadS := 0
    nGSaySaldS := 0
    nGPercBarS := 0
    cGSayBlqS := "NÃO"

    RefreshDlg()

Return .T.

Static Function RefreshDlg()

    oCProgBarV:nWidth := Round(nPxProgBr * Min(nCPercBarV,100) / 100 * 2, 0)
    oGProgBarV:nWidth := Round(nPxProgBr * Min(nGPercBarV,100) / 100 * 2, 0)
    oCProgBarS:nWidth := Round(nPxProgBr * Min(nCPercBarS,100) / 100 * 2, 0)
    oGProgBarS:nWidth := Round(nPxProgBr * Min(nGPercBarS,100) / 100 * 2, 0)

    oNomCli:Refresh()
    oNmFant:Refresh()
    oEndCli:Refresh()
    oTpPessoa:Refresh()
    oRgInsc:Refresh()
    oDtCad:Refresh()
    oTpDoc:Refresh()
    oEmitCheq:Refresh()
    oEmitCarta:Refresh()
    oObrPlaca:Refresh()
    oObrPlacAm:Refresh()
    oObrKM:Refresh()
    oObrMotor:Refresh()
    oGrupoCli:Refresh()
    oClasseFat:Refresh()

    oListPlacas:SetArray( aListPlacas )
    oListPlacas:bLine := {|| Retbline(oListPlacas, aListPlacas ) }
    oListPlacas:Refresh()

    oListNegPag:SetArray( aListNegPag )
    oListNegPag:bLine := {|| Retbline(oListNegPag, aListNegPag ) }
    oListNegPag:Refresh()

    oListPrcNeg:SetArray( aListPrcNeg )
    oListPrcNeg:bLine := {|| Retbline(oListPrcNeg, aListPrcNeg ) }
    oListPrcNeg:Refresh()

    oCSayLimV:Refresh()
    oCSayUsadV:Refresh()
    oCSaySaldV:Refresh()
    oCProgBarV:Refresh()
    oCSayBarV:Refresh()
    oCSayBlqV:Refresh()
    oGSayLimV:Refresh()
    oGSayUsadV:Refresh()
    oGSaySaldV:Refresh()
    oGProgBarV :Refresh()
    oGSayBarV :Refresh()
    oGSayBlqV:Refresh()
    oCSayLimS:Refresh()
    oCSayUsadS:Refresh()
    oCSaySaldS:Refresh()
    oCProgBarS:Refresh()
    oCSayBarS:Refresh()
    oCSayBlqS:Refresh()
    oGSayLimS:Refresh()
    oGSayUsadS:Refresh()
    oGSaySaldS:Refresh()
    oGProgBarS:Refresh()
    oGSayBarS:Refresh()
    oGSayBlqS:Refresh()

Return

Static Function RetbLine(oLbx, aLista)
    Local nx
    Local aRet	:= {}

    If oLbx:nAt == 0 .OR. Empty(aLista)
        aadd(aRet,{})
        aEval(oLbx:aHeaders, {|| aadd(aRet[1], "" )})
        Return aclone(aRet)
    EndIf 

    For nX := 1 to len(aLista[oLbx:nAt])
        aadd(aRet,aLista[oLbx:nAt,nX])
    Next
Return aclone(aRet)


Static Function DoBuscaDados(cCliSel, cLojSel, aLimVenda,aLimSaque)

    Local cHoraInicio
    Local aParam
    Local lOk := .T.
    Local lTP_ACTLCS := SuperGetMv("TP_ACTLCS",,.F.) //habilita limite de credito por segmento
	Local cSegmento := SuperGetMv("TP_MYSEGLC",," ") //define o segmento da filial do PDV
    Local cLCOffline := SuperGetMV("TP_LCOFFLI",,"0") //define se vai usar limite offline e como vai usar: 0=Somente online; 1=Prioriza Online; 2=Apenas Offline

    CursorArrow()

    STFMessage(ProcName(),"STOP","Pesquisando limites de crédito do cliente"+iif(cLCOffline <> "2"," no Back-Office","")+". Aguarde...")
    STFShowMessage(ProcName())

    CursorWait()

    cHoraInicio := TIME() // Armazena hora de inicio do processamento...
    LjGrvLog("TPDVA013", "INICIO - Retorna o limite utilizado de um CLIENTE e GRUPO DE CLIENTE",)

    //Buscando os limites de venda
    aLimVenda := {}
    aParam := {}
    aadd(aParam,{cCliSel,cLojSel,""})
    aParam := {1,aParam}
    if lTP_ACTLCS
        aadd(aParam, cSegmento)
    endif
    if cLCOffline <> "2" //so nao pesquisa online se parametro define apenas offline
        If STBRemoteExecute("_EXEC_RET", {"U_TRETE032",aParam},,, @aLimVenda)
            If ValType(aLimVenda) == "A" .AND. Len(aLimVenda)>0
            Else
                lOk := .F.
                aLimVenda := {}
            EndIf
        Else
            lOk := .F.
            aLimVenda := {}
        EndIf
    endif
    if empty(aLimVenda) .AND. cLCOffline <> "0" //so nao pesquisa offline se parametro define apenas online
        aLimVenda := U_TR032OFF(aParam[1],aParam[2],iif(lTP_ACTLCS,aParam[3],))
        lOk := !empty(aLimVenda)
    endif

    //Buscando limites de saque
    if lOk
        aLimSaque := {}
        aParam := {}
        aadd(aParam,{cCliSel,cLojSel,""})
        aParam := {2,aParam}
        if lTP_ACTLCS
            aadd(aParam, cSegmento)
        endif
        if cLCOffline <> "2" //so nao pesquisa online se parametro define apenas offline
            If STBRemoteExecute("_EXEC_RET", {"U_TRETE032",aParam},,, @aLimSaque)
                If ValType(aLimSaque) == "A" .AND. Len(aLimSaque)>0
                Else
                    lOk := .F.
                    aLimSaque := {}
                EndIf
            Else
                lOk := .F.
                aLimSaque := {}
            EndIf
        endif
        if empty(aLimSaque) .AND. cLCOffline <> "0" //so nao pesquisa offline se parametro define apenas online
            aLimSaque := U_TR032OFF(aParam[1],aParam[2],iif(lTP_ACTLCS,aParam[3],))
            lOk := !empty(aLimSaque)
        endif
    endif

    LjGrvLog("TPDVA013", "Tempo de processamento: ", ElapTime( cHoraInicio, TIME() ))
    LjGrvLog("TPDVA013", "FIM - Retorna o limite utilizado de um CLIENTE e GRUPO DE CLIENTE",)

    CursorArrow()
    STFCleanMessage()
	STFCleanInterfaceMessage()

Return lOk

Static Function LoadPlacas(cCodCli, cLojCli, cGrpCli)

    Local cQry
    Local aRet := {}

    cQry:= "SELECT DA3_PLACA, DA3_DESC, DA3_XCODCL, DA3_XLOJCL, DA3_XGRPCL "
	cQry+= "FROM "+RetSqlName("DA3")+" DA3 "
	cQry+= "WHERE DA3.D_E_L_E_T_ <> '*' "
	cQry+= "  AND DA3_FILIAL = '"+xFilial("DA3")+"' "
    if !empty(cGrpCli)
        cQry+= "AND (DA3_XGRPCL = '"+cGrpCli+"' "
        cQry+= "OR (DA3_XCODCL = '"+cCodCli+"' "
        cQry+= "AND DA3_XLOJCL = '"+cLojCli+"')) "
    else
        cQry+= "AND DA3_XCODCL = '"+cCodCli+"' "
        cQry+= "AND DA3_XLOJCL = '"+cLojCli+"' "
    endif
    cQry+= "ORDER BY DA3_PLACA "

	if Select("QRYPLACA") > 0
		QRYPLACA->(DbCloseArea())
	Endif

	cQry := ChangeQuery(cQry)

	TcQuery cQry New Alias "QRYPLACA" // Cria uma nova area com o resultado do query

	QRYPLACA->(DbGoTop())
	While QRYPLACA->(!Eof())

		AADD(aRet,{QRYPLACA->DA3_PLACA, QRYPLACA->DA3_DESC, QRYPLACA->DA3_XCODCL + "/"+ QRYPLACA->DA3_XLOJCL, QRYPLACA->DA3_XGRPCL})

		QRYPLACA->(DbSkip())
	EndDo

    if Select("QRYPLACA") > 0
		QRYPLACA->(DbCloseArea())
	Endif
    
Return aRet

Static Function LoadNegPag(cCodCli, cLojCli, cGrpCli)

    Local cQry
    Local aRet := {}

    cQry := "SELECT U53_FORMPG, U53_CONDPG, U53_DESCRI, U53_TPRGNG, U53_CODPRO, U53_DESCPR, U53_GRUPO, U53_DESCGR, U53_CODCLI, U53_LOJA, U53_GRPVEN"
	cQry += "FROM "+RetSqlName("U53")+" U53 "
	cQry += "INNER JOIN "+RetSqlName("U44")+" U44 "
	cQry += "ON (U44.D_E_L_E_T_ = ' ' AND U44_PADRAO = 'N' AND U44_FILIAL = '" + xFilial("U44") + "' AND U53_FORMPG = U44_FORMPG AND U53_CONDPG = U44_CONDPG) "
	cQry += "WHERE U53_FILIAL = '"+xFilial("U53")+"' "
	cQry += " AND ( (U53_CODCLI = '"+alltrim(cCodCli)+"' AND U53_LOJA = '"+alltrim(cLojCli)+"' )"
	if !empty(cGrpCli)
		cQry += "	OR (U53_GRPVEN = '"+alltrim(cGrpCli)+"' ) "
	endif
	cQry += " ) "
	cQry += "ORDER BY U53_FORMPG, U53_CONDPG, U53_TPRGNG DESC, U53_CODPRO, U53_GRUPO "

	if Select("QRYNEG") > 0
		QRYNEG->(DbCloseArea())
	Endif

	cQry := ChangeQuery(cQry)

	TcQuery cQry New Alias "QRYNEG" // Cria uma nova area com o resultado do query

	QRYNEG->(DbGoTop())
	While QRYNEG->(!Eof())

        //"Forma","Condição","Descriçao","Tipo","Produto","Desc.Prod","Grupo Prod.","Desc.Grupo","Cliente","Grupo Cli."
		AADD(aRet,{QRYNEG->U53_FORMPG, QRYNEG->U53_CONDPG, QRYNEG->U53_DESCRI, ;
                    iif(QRYNEG->U53_TPRGNG=="R","Regra","Exceção"),;
                    QRYNEG->U53_CODPRO, QRYNEG->U53_DESCPR, QRYNEG->U53_GRUPO, QRYNEG->U53_DESCGR,;
                    QRYNEG->U53_CODCLI + "/"+ QRYNEG->U53_LOJA, QRYNEG->U53_GRPVEN ;
                    })

		QRYNEG->(DbSkip())
	EndDo

    if Select("QRYNEG") > 0
		QRYNEG->(DbCloseArea())
	Endif

Return aRet

Static Function LoadPrcNeg(cCodCli, cLojCli, cGrpCli)

    Local cQry
    Local aRet := {}
    Local lNgDesc := SuperGetMV("MV_XNGDESC",,.T.) //Ativa negociação pelo valor de desconto: U25_DESPBA

    cQry := "SELECT U25_PRODUT, SB1.B1_DESC, U25_PRCVEN, U25_FORPAG, U25_CONDPG, ISNULL(U44_DESCRI,'') U44_DESCRI, "
    cQry += "U25_ADMFIN, U25_CLIENT, U25_LOJA, U25_GRPCLI, "

    //PREÇO BASE E DESCONTO/ACRESCIMO
    if lNgDesc
        cQry += "U25_DESPBA "
    endif

	cQry += "FROM "+RetSqlName("U25")+" U25 "

    cQry += " INNER JOIN "+RetSqlName("SB1")+" SB1 ON ("
    cQry += "   SB1.D_E_L_E_T_ = ' ' "
    cQry += "   AND B1_FILIAL = '"+xFilial("SB1")+"'"
    cQry += "   AND B1_COD = U25_PRODUT  "
    cQry += " ) "

    cQry += " LEFT JOIN "+RetSqlName("U44")+" U44 ON ("
    cQry += "   U44.D_E_L_E_T_ = ' '  "
    cQry += "   AND U44_FILIAL = '"+xFilial("U44")+"' "
    cQry += "   AND U44_FORMPG = U25_FORPAG "
    cQry += "   AND U44_CONDPG = U25_CONDPG "
    cQry += " ) "

    cQry += " WHERE U25.D_E_L_E_T_ = ' ' "
    cQry += " AND U25_FILIAL = '" + xFilial("U25") + "' "

    //FILTRO PREÇOS VIGENTES
    cQry += " AND U25_DTINIC + U25_HRINIC <= '"+DTOS(dDataBase)+SubStr(Time(),1,5)+"' "
    cQry += " AND (U25_DTFIM = '        ' OR (U25_DTFIM + U25_HRFIM >= '"+DTOS(dDataBase)+""+SubStr(Time(),1,5)+"')) "

    if empty(cGrpCli)
        cQry += "	AND (U25_CLIENT = '"+cCodCli+"' AND U25_LOJA = '"+cLojCli+"') "
    else
        cQry += "	AND ((U25_CLIENT = '"+cCodCli+"' AND U25_LOJA = '"+cLojCli+"') OR U25_GRPCLI = '"+cGrpCli+"') "
    endif

	cQry += " ORDER BY U25_PRODUT, U25_FORPAG, U25_CONDPG  "

	if Select("QRYPRC") > 0
		QRYPRC->(DbCloseArea())
	Endif

	cQry := ChangeQuery(cQry)

	TcQuery cQry New Alias "QRYPRC" // Cria uma nova area com o resultado do query

	QRYPRC->(DbGoTop())
	While QRYPRC->(!Eof())
        
        nPrcBas := 0
        if lNgDesc
            nPrcBas := U_URetPrBa(QRYPRC->U25_PRODUT, QRYPRC->U25_FORPAG, QRYPRC->U25_CONDPG, QRYPRC->U25_ADMFIN, 0, dDataBase, SubStr(Time(),1,5))
        else
            nPrcBas := U_URetPrec(QRYPRC->U25_PRODUT,,.F.)
        endif

        //"Produto","Desc.Prod","Preço Base","Desconto","Preço Negociado","Forma","Condição","Descriçao","Adm Fin","Desc.Adm.Fin.","Cliente","Grupo Cli."
		AADD(aRet,{ QRYPRC->U25_PRODUT, ;
                    QRYPRC->B1_DESC, ;
                    AllTrim(Transform( nPrcBas ,"@E 999,999,999.99")) , ;
                    AllTrim(Transform( iif(lNgDesc, QRYPRC->U25_DESPBA, nPrcBas-QRYPRC->U25_PRCVEN) ,"@E 999,999,999.99")) , ;
                    AllTrim(Transform( iif(lNgDesc, nPrcBas-QRYPRC->U25_DESPBA, QRYPRC->U25_PRCVEN) ,"@E 999,999,999.99")) , ;
                    QRYPRC->U25_FORPAG, ;
                    QRYPRC->U25_CONDPG, ;
                    QRYPRC->U44_DESCRI, ;
                    QRYPRC->U25_ADMFIN, ;
                    Alltrim(Posicione("SAE",1,xFilial("SAE")+QRYPRC->U25_ADMFIN,"AE_DESC")), ;
                    QRYPRC->U25_CLIENT + "/"+ QRYPRC->U25_LOJA, ;
                    QRYPRC->U25_GRPCLI ;
        })

		QRYPRC->(DbSkip())
	EndDo

    if Select("QRYPRC") > 0
		QRYPRC->(DbCloseArea())
	Endif

Return aRet
