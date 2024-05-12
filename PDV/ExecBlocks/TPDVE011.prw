#include 'poscss.ch'
#include "TOTVS.CH"
#include 'stpos.ch'
#include "FWMVCDEF.CH"

/*/{Protheus.doc} TPDVA010
Busca atualização da retaguarda do cliente: UCA - Conf. de Carga por Registro.

@author Totvs GO
@since 12/08/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TPDVE011()

Private oCgcCli
Private cCgcCli := Space(TamSX3("A1_CGC")[1])
Private oCodCli
Private cCodCli := Space(TamSX3("A1_COD")[1])
Private oLojCli
Private cLojCli := Space(TamSX3("A1_LOJA")[1])
Private oNomCli
Private cNomCli := Space(TamSX3("A1_NOME")[1])
Private oAtuClientes

Private nWidth := 0
Private nHeight := 0

//limpa as tecla atalho
U_UKeyCtr() 

DEFINE MSDIALOG oAtuClientes TITLE "" FROM 000,000 TO 220,500 PIXEL STYLE nOr(WS_VISIBLE, WS_POPUP)

    nWidth  := (oAtuClientes:nWidth/2)
    nHeight := (oAtuClientes:nHeight/2)

    @ 000, 000 MSPANEL oPanelCli SIZE nWidth, nHeight OF oAtuClientes
    oPanelCli:SetCSS( "TPanel{border: 2px solid #999999; background-color: #f4f4f4;}" )

    @ 000, 000 MSPANEL oPnlTop SIZE nWidth, 017 OF oPanelCli
    oPnlTop:SetCSS( POSCSS (GetClassName(oPnlTop), CSS_BAR_TOP ))
    @ 004, 005 SAY oSay1 PROMPT " Atualizar Cliente / Grupo de Cliente " SIZE 150, 015 OF oPnlTop COLORS 0, 16777215 PIXEL
    oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BREADCUMB ))
    oClose := TBtnBmp2():New( 002,oAtuClientes:nWidth-25,20,30,'FWSKIN_DELETE_ICO',,,,{|| oAtuClientes:End()},oPnlTop,,,.T. )
    oClose:SetCss("TBtnBmp2{border: none;background-color: none;}")

    @ 025, 010 SAY oSay3 PROMPT "Código" SIZE 050, 008 OF oPanelCli COLORS 0, 16777215 PIXEL
    oSay3:SetCSS( POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL ))
    oCodCli := TGet():New( 035, 010, {|u| iif( PCount()==0,cCodCli,cCodCli:=u) },oPanelCli, 060, 013, "@!",{|| VldCliente() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cCodCli",,,,.T.,.F.)
    oCodCli:SetCSS( POSCSS (GetClassName(oCodCli), CSS_GET_NORMAL ))

    @ 025, 075 SAY oSay4 PROMPT "Loja" SIZE 050, 008 OF oPanelCli COLORS 0, 16777215 PIXEL
    oSay4:SetCSS( POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL ))
    oLojCli := TGet():New( 035, 075, {|u| iif( PCount()==0,cLojCli,cLojCli:=u) },oPanelCli, 020, 013, "@!",{|| VldCliente() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cLojCli",,,,.T.,.F.)
    oLojCli:SetCSS( POSCSS (GetClassName(oLojCli), CSS_GET_NORMAL ))

    @ 025, 100 SAY oSay2 PROMPT "CPF/CNPJ" SIZE 060, 008 OF oPanelCli COLORS 0, 16777215 PIXEL
    oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))
    oCgcCli := TGet():New( 035, 100, {|u| iif( PCount()==0,cCgcCli,cCgcCli:=u) },oPanelCli, 080, 013, "@!",{|| VldCliente() },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cCgcCli",,,,.T.,.F.)
    oCgcCli:SetCSS( POSCSS (GetClassName(oCgcCli), CSS_GET_NORMAL ))

    @ 055, 010 SAY oSay5 PROMPT "Nome" SIZE 070, 008 OF oPanelCli COLORS 0, 16777215 PIXEL
    oSay5:SetCSS( POSCSS (GetClassName(oSay5), CSS_LABEL_FOCAL ))
    oNomCli := TGet():New( 065, 010,{|u| iif( PCount()==0,cNomCli,cNomCli:=u)},oPanelCli, nWidth-020, 013, "@!",{|| .T. },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"cNomCli",,,,.T.,.F.)
    oNomCli:SetCSS( POSCSS (GetClassName(oNomCli), CSS_GET_NORMAL ))
    oNomCli:lCanGotFocus := .F.

    TSearchF3():New(oCodCli,400,250,"SA1","A1_COD",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'",{{"A1_NOME","A1_EST","A1_MUN"},{"A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,0,,{{oLojCli,"A1_LOJA"},{oCgcCli,"A1_CGC"},{oNomCli,"A1_NOME"}})
    TSearchF3():New(oCgcCli,400,250,"SA1","A1_CGC",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'",{{"A1_NOME","A1_EST","A1_MUN"},{"A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}},,,0,,{{oCodCli,"A1_COD"},{oLojCli,"A1_LOJA"},{oNomCli,"A1_NOME"}})

    // BOTAO ATUALIZAR
    oBtn1 := TButton():New( nHeight-030,nWidth-080,"&Atualizar",oPanelCli,{|| AtuCadSA1() },070,020,,,,.T.,,,,{|| .T.})
    oBtn1:SetCSS( POSCSS (GetClassName(oBtn1), CSS_BTN_FOCAL ))

    oBtn2 := TButton():New( nHeight-030,nWidth-155,"&Limpar",oPanelCli,{|| ClearCli() },070,020,,,,.T.,,,,{|| .T.})
    oBtn2:SetCSS( POSCSS (GetClassName(oBtn2), CSS_BTN_NORMAL ))

ACTIVATE MSDIALOG oAtuClientes CENTERED

//restaura as teclas atalho
U_UKeyCtr(.T.)

Return

//--------------------------------------------------------
// Validação e gatilho do cliente
//--------------------------------------------------------
Static Function VldCliente(cCampo)

    Local lRet := .T.
    Default cCampo := ReadVar()

    If Upper(AllTrim(cCampo)) == 'CCGCCLI'
        If Empty(cCgcCli)
            cNomCli := Space(TamSX3("A1_NOME")[1])
            cCodCli := Space(TamSX3("A1_COD")[1])
            cLojCli := Space(TamSX3("A1_LOJA")[1])
        Else
            cNomCli := Posicione("SA1",3,xFilial("SA1")+cCgcCli,"A1_NOME") //A1_FILIAL+A1_CGC
            cCodCli := Posicione("SA1",3,xFilial("SA1")+cCgcCli,"A1_COD")
            cLojCli := Posicione("SA1",3,xFilial("SA1")+cCgcCli,"A1_LOJA")
        EndIf

    ElseIf Upper(AllTrim(cCampo)) == 'CLOJCLI'
        If !Empty(cCodCli) .and. !Empty(cLojCli)
            cNomCli := Posicione("SA1",1,xFilial("SA1")+cCodCli+cLojCli,"A1_NOME") //A1_FILIAL+A1_COD+A1_LOJA
            cCgcCli := Posicione("SA1",1,xFilial("SA1")+cCodCli+cLojCli,"A1_CGC") 
        EndIf

    EndIf
    
    oNomCli:Refresh()
	
Return lRet

//--------------------------------------------------------
// Limpar gets
//--------------------------------------------------------
Static Function ClearCli()

    cNomCli := Space(TamSX3("A1_NOME")[1])
    cCgcCli := Space(TamSX3("A1_CGC")[1])
    cCodCli := Space(TamSX3("A1_COD")[1])
    cLojCli := Space(TamSX3("A1_LOJA")[1])

Return .T.

//--------------------------------------------------------
// Atualiza Cadastro SA1
//--------------------------------------------------------
Static Function AtuCadSA1()
Local aRegAtu := {}
Local cCampo  := ""
Local lRet := .F.

If !Empty(cCodCli) .and. !Empty(cLojCli)
    cCampo := "cCodCli"
    SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
    If SA1->(DbSeek(xFilial("SA1") + cCodCli + cLojCli ))
        aadd(aRegAtu, {"SA1", 1, xFilial("SA1")+SA1->A1_COD+SA1->A1_LOJA, .T. /*atualiza tbm esse registro*/, ""/*todas tabelas filhas*/, .F. /*nao deletado*/} )
        If !Empty(SA1->A1_GRPVEN)
            aadd(aRegAtu, {"ACY", 1, xFilial("ACY")+SA1->A1_GRPVEN, .T. /*atualiza tbm esse registro*/, ""/*todas tabelas filhas*/, .F. /*nao deletado*/} )
        EndIf
    EndIf
ElseIf !Empty(cCgcCli)
    cCampo := "cCgcCli"
    aadd(aRegAtu, {"SA1", 3, xFilial("SA1")+cCgcCli, .T. /*atualiza tbm esse registro*/, ""/*todas tabelas filhas*/, .F. /*nao deletado*/} )
    SA1->(DbSetOrder(3)) //A1_FILIAL+A1_CGC
    If SA1->(DbSeek(xFilial("SA1") + cCgcCli ))
        If !Empty(SA1->A1_GRPVEN)
            aadd(aRegAtu, {"ACY", 1, xFilial("ACY")+SA1->A1_GRPVEN, .T. /*atualiza tbm esse registro*/, ""/*todas tabelas filhas*/, .F. /*nao deletado*/} )
        EndIf
    EndIf
EndIf

If Len(aRegAtu) > 0
    FWMsgRun(,{|oAtuClientes| lRet := U_TPDVA10A(cFilAnt, aRegAtu) },"Atualizar Cadastros","Aguarde... Buscando cliente na Retaguarda...") //U_TPDVA10A(cFilAnt, aRegAtu)
    If lRet
        MsgInfo("Atualização realizada com sucesso!")
        VldCliente(cCampo)
    Else
        MsgInfo("Não foi possível atualizar dados!")
    EndIf
Else
    MsgInfo("Informe Codigo+Loja ou CPF/CNPJ para buscar dados.")
EndIf

Return
