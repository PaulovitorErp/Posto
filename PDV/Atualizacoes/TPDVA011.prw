#include 'totvs.ch'
#include 'poscss.ch'
#include "FWPrintSetup.ch"
#include "RPTDEF.CH"

Static cTitleTela 	:= "REIMPRESSÃO DE DOCUMENTOS"
Static oSerieNf
Static cSerieNf     := Space(TamSX3("F2_SERIE")[1])
Static oDocumNf
Static cDocumNf     := Space(TamSX3("F2_DOC")[1])

/*/{Protheus.doc} TPDVA011
Reimpressão de Documentos

@author TOTVS
@since 05/09/2019
@version 1.0
@return Nil
@type function
/*/
User Function TPDVA011(oPnlPrinc,bConfirm,bCancel)

    Local oPnlGeral, oPnlReimp
    Local nWidth, nHeight

    nWidth := oPnlPrinc:nWidth/2
    nHeight := oPnlPrinc:nHeight/2

// Painel geral da tela
    oPnlGeral := TPanel():New(000,000,"",oPnlPrinc,NIL,.T.,.F.,,,nWidth,nHeight,.T.,.F.)

    @ 002, 002 SAY oSay1 PROMPT (cTitleTela) SIZE nWidth-004, 015 OF oPnlGeral COLORS 0, 16777215 PIXEL CENTER
    oSay1:SetCSS(POSCSS(GetClassName(oSay1), CSS_BTN_FOCAL))

//Painel de reimpressão
    oPnlReimp := TPanel():New(020,000,"",oPnlGeral,NIL,.T.,.F.,,,nWidth,nHeight-020,,.T.,.F.)

    @ 005, 005 SAY oSay2 PROMPT "Informe a série e o número do Documento Fiscal e defina o tipo de impressão." SIZE nWidth, 030 OF oPnlReimp COLORS 0, 16777215 PIXEL
    oSay2:SetCSS(POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL))

    @ 040, 005 SAY oSay3 PROMPT "Série" SIZE 100, 010 OF oPnlReimp COLORS 0, 16777215 PIXEL
    oSay3:SetCSS(POSCSS (GetClassName(oSay3), CSS_LABEL_FOCAL))
    oSerieNf := TGet():New(050, 005,{|u| iif(PCount()==0,cSerieNf,cSerieNf:=u) },oPnlReimp, 030, 013,,{|| .T. },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oSerieNf",,,,.T.,.F.)
    oSerieNf:SetCSS(POSCSS(GetClassName(oSerieNf), CSS_GET_NORMAL))

    @ 070, 005 SAY oSay4 PROMPT "Número Doc." SIZE 100, 010 OF oPnlReimp COLORS 0, 16777215 PIXEL
    oSay4:SetCSS(POSCSS (GetClassName(oSay4), CSS_LABEL_FOCAL))
    oDocumNf := TGet():New(080, 005,{|u| iif(PCount()==0,cDocumNf,cDocumNf:=u) },oPnlReimp, 080, 013,,{|| ValidDoc()/*bValid*/},,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oDocumNf",,,,.T.,.F.)
    oDocumNf:SetCSS(POSCSS(GetClassName(oDocumNf), CSS_GET_NORMAL))

    oBtn := TButton():New( nHeight-45,005,"DANFE (A4)",oPnlReimp,{|| ImpDanfe() },070,020,,,,.T.,,,,{|| .T. })
    oBtn:SetCSS( POSCSS (GetClassName(oBtn), CSS_BTN_FOCAL ))

    oBtn2 := TButton():New( nHeight-45,080,"IMPRES. NÃO-FISCAL",oPnlReimp,{|| ImpNFiscal() },090,020,,,,.T.,,,,{|| .T. })
    oBtn2:SetCSS( POSCSS (GetClassName(oBtn2), CSS_BTN_FOCAL ))

    oSerieNf:SetFocus()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} TPDVA11C
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function TPDVA11C()

    cSerieNf  := Space(TamSX3("F2_SERIE")[1])
    cDocumNf  := Space(TamSX3("F2_DOC")[1])

    oSerieNf:SetFocus()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} ImpDanfe
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function ImpDanfe()

    Local nFlags
    Local oSetup
    Local cDestino      := ""

    Private nRecnoSF2

    //verifica o SITUA do documento antes de prosseguir com a impressão
	If !SitCanc(cDocumNf,cSerieNf)
        Return
    EndIf

    DbSelectArea("SF2")
    SF2->(DbSetOrder(1)) // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
    SF2->(DbSeek(xFilial("SF2")+cDocumNf+cSerieNf))

    If SF2->(EOF()) //ajusta o campo DOC com zeros a esquerda
        cDocumNf := PadL(AllTrim(cDocumNf),TamSX3("F2_DOC")[1],"0")
        SF2->(DbSeek(xFilial("SF2")+cDocumNf+cSerieNf))
    EndIf

    If SF2->(!EOF())

        If AllTrim(SF2->F2_ESPECIE) == "SPED" // NF-e

            nRecnoSF2 := SF2->(Recno())

            nFlags := PD_ISTOTVSPRINTER + PD_DISABLEDESTINATION + PD_DISABLEORIENTATION + PD_DISABLEPAPERSIZE + PD_DISABLEPREVIEW + PD_DISABLEMARGIN
            oSetup := FWPrintSetup():New(nFlags,"IMPRESSAO DANFE")
            oSetup:SetPropert(PD_PRINTTYPE   , IMP_PDF)
            oSetup:SetPropert(PD_DESTINATION , 2) // Client
            oSetup:SetPropert(PD_MARGIN      , {60,60,60,60})
            oSetup:CQTDCOPIA := "01"

            If oSetup:Activate() == PD_OK
                cDestino := oSetup:aOptions[6]
                nRet := GeraDoc(cDestino,oSetup)
                IIF(nRet > 0,U_SetMsgRod("IMPRESSAO DO DANFE CONCLUIDA!"),U_SetMsgRod("NENHUM DOCUMENTO IMPRESSO!"))
            EndIf

            FreeObj(oSetup)
            oSetup := Nil
        Else
            U_SetMsgRod("SERIE/DOCUMENTO DIFERENTE DE NF-E!")
        EndIf
    Else
        U_SetMsgRod("SERIE/DOCUMENTO NAO LOCALIZADO NESTE PDV!")
    EndIf

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} GeraDoc
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function GeraDoc(cDestino,oSetup)

    Local nRet 	:= 0
    Local oBjNfe
    Local cAliasSX1 := GetNextAlias() // apelido para o arquivo de trabalho
    Local lOpen   	:= .F. // valida se foi aberto a tabela
    Local cMV_CH := ""
    
    // abre o dicionário SX1
    /*OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX1, "SX1", NIL, .F.)
    lOpen := Select(cAliasSX1) > 0

    // caso aberto, posiciona no topo
    If !(lOpen)
        Return .F.
    EndIf

    DbSelectArea(cAliasSX1)
    (cAliasSX1)->( DbSetOrder( 1 ) ) //X1_GRUPO+X1_ORDEM
    (cAliasSX1)->( DbGoTop() )
    (cAliasSX1)->( DbSeek("NFSIGW") )
    
    cMV_CH := Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) //verifica em qual MV_CH começa: 0 ou 1

    While !(cAliasSX1)->( Eof() ) .and. AllTrim((cAliasSX1)->&("X1_GRUPO")) == "NFSIGW"

        RecLock(cAliasSX1)

        If(cVersao == "11" .or. "TOTVS 2011" $ cVersao .or. cMV_CH == "MV_CH1")

            Do case
            Case Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) == "MV_CH1"	// Da Nota Fiscal ?
                (cAliasSX1)->&("X1_CNT01") := cDocumNf //Substr(SPDX->NFE_ID,4,9)
                MV_PAR01 := (cAliasSX1)->&("X1_CNT01")
            Case Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) == "MV_CH2"	// Ate a Nota Fiscal ?
                (cAliasSX1)->&("X1_CNT01") := cDocumNf //Substr(SPDX->NFE_ID,4,9)
                MV_PAR02 := (cAliasSX1)->&("X1_CNT01")
            Case Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) == "MV_CH3"	// Da Serie ?
                (cAliasSX1)->&("X1_CNT01") := cSerieNf //Left(SPDX->NFE_ID,3)
                MV_PAR03 := (cAliasSX1)->&("X1_CNT01")
            Case Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) == "MV_CH4"	// Tipo de Operacao ? (1)Entrada / (2)Saida
                (cAliasSX1)->&("X1_CNT01") := "2"
                MV_PAR04 := 2
            Case Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) == "MV_CH5"	// Imprime no verso?
                (cAliasSX1)->&("X1_CNT01") := "2"
                MV_PAR05 := 2
            Case Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) == "MV_CH6"	// Danfe Simplificado?
                (cAliasSX1)->&("X1_CNT01") := ""
                MV_PAR06 := ""
            EndCase
        Else
            Do case
            Case Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) == "MV_CH0"	// Da Nota Fiscal ?
                (cAliasSX1)->&("X1_CNT01") := cDocumNf //Substr(SPDX->NFE_ID,4,9)
                MV_PAR01 := (cAliasSX1)->&("X1_CNT01")
            Case Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) == "MV_CH1"	// Ate a Nota Fiscal ?
                (cAliasSX1)->&("X1_CNT01") := cDocumNf //Substr(SPDX->NFE_ID,4,9)
                MV_PAR02 := (cAliasSX1)->&("X1_CNT01")
            Case Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) == "MV_CH2"	// Da Serie ?
                (cAliasSX1)->&("X1_CNT01") := cSerieNf //Left(SPDX->NFE_ID,3)
                MV_PAR03 := (cAliasSX1)->&("X1_CNT01")
            Case Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) == "MV_CH3"	// Tipo de Operacao ? (1)Entrada / (2)Saida
                (cAliasSX1)->&("X1_CNT01") := "2"
                MV_PAR04 := 2
            Case Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) == "MV_CH4"	// Imprime no verso?
                (cAliasSX1)->&("X1_CNT01") := "2"
                MV_PAR05 := 2
            EndCase
        Endif

        (cAliasSX1)->( DbUnLock() )
        (cAliasSX1)->( DbCommit() )

        (cAliasSX1)->( DbSkip() )
    EndDo

//Compatibiliza tamanho dos parâmetros
    MV_PAR01 := cDocumNf
    MV_PAR02 := cDocumNf
    MV_PAR03 := cSerieNf

//TBC - erro: argument #0 error, expected D->C,  function DTOS on DANFEPROC(DANFEII.PRW) 12/04/2019 16:34:41 line : 612
    MV_PAR07 := SF2->F2_EMISSAO
    MV_PAR08 := SF2->F2_EMISSAO
    */

    Pergunte("NFSIGW",.F.)
    SetMVValue("NFSIGW","MV_PAR01",cDocumNf) // Da Nota Fiscal ?
    SetMVValue("NFSIGW","MV_PAR02",cDocumNf) // Ate a Nota Fiscal ?
    SetMVValue("NFSIGW","MV_PAR03",cSerieNf) // Da Serie ?
    SetMVValue("NFSIGW","MV_PAR04",2) //Tipo de Operacao ? (1)Entrada / (2)Saida
    SetMVValue("NFSIGW","MV_PAR07",SF2->F2_EMISSAO) //data emissao de
    SetMVValue("NFSIGW","MV_PAR08",SF2->F2_EMISSAO) //data emissao ate
    Pergunte("NFSIGW",.F.) 

//Apaga arquivo se já existir
    FErase(cDestino + AllTrim(cSerieNf)+AllTrim(cDocumNf) + ".rel")
    FErase(cDestino + AllTrim(cSerieNf)+AllTrim(cDocumNf) + ".pdf")

    cFilePrint	:= AllTrim(cSerieNf)+AllTrim(cDocumNf)
    oBjNfe		:= FWMSPrinter():New(cFilePrint /*Nome Arq*/, IMP_PDF /*IMP_SPOOL/IMP_PDF*/, .F. /*3-Legado*/,;
                /*4-Dir. Salvar*/, .T. /*5-Não Exibe Setup*/, /*6-Classe TReport*/,;
        oSetup /*7-oPrintSetup*/, ""  /*8-Impressora Forçada*/,;
        .F. /*lServer*/, /*lPDFAsPNG*/, /*lRaw*/, .F. /*lViewPDF*/)
    oBjNfe:SetResolution(78) //Tamanho estipulado para a Danfe
    oBjNfe:SetPortrait()
    oBjNfe:SetPaperSize(DMPAPER_A4)
    oBjNfe:nDevice 	:= IMP_PDF
    oBjNfe:cPathPDF := cDestino

    SF2->(DbGoTo(nRecnoSF2))

    If FindFunction("LjTSSIDEnt")
        cIdEnt := LjTSSIDEnt(IIF(!Empty(SF2->F2_PDV),"65","55"))
    Else
        //cIdEnt := StaticCall(LOJNFCE, LjTSSIDEnt, IIF(!Empty(SF2->F2_PDV),"65","55"))
        cIdEnt := &("StaticCall(LOJNFCE, LjTSSIDEnt, '"+IIF(!Empty(SF2->F2_PDV),"65","55")+"')")
    EndIf

    U_SetMsgRod("IMPRIMINDO DANFE...")

    If U_PrtNfeSef(cIdEnt, "", "", oBjNfe, oSetup, cFilePrint, .T., 0) //Rdmake de exemplo para impressão da DANFE no formato Retrato
        nRet++
    Endif

    FreeObj(oBjNfe)
    oBjNfe := Nil

Return nRet

//-------------------------------------------------------------------
/*/{Protheus.doc} ImpNFiscal
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function ImpNFiscal()

    //verifica o SITUA do documento antes de prosseguir com a impressão
	If !SitCanc(cDocumNf,cSerieNf)
        Return
    EndIf

    If !Empty(cDocumNf) .And. !Empty(cSerieNf)
        
        U_SetMsgRod("IMPRIMINDO DANFE...")        
        LjNfceImp(SL1->L1_FILIAL,SL1->L1_NUM)
        U_TPDVR001() //Chama a impressão do comprovante venda a prazo
        
        //-------------------------------------------------------------//
        // Faz impressão do comprovante de Vale Haver
        //-------------------------------------------------------------//
        If SL1->L1_XTROCVL > 0
            U_SetMsgRod("IMPRIMINDO VALE HAVER...")  
            U_TPDVR006(SL1->L1_XTROCVL, .F./*lCmp*/, AllTrim(SL1->L1_SERIE))
        EndIf

		//--------------------------------------------------------------//
		// Faço a impressão customizada da carta frete
		//--------------------------------------------------------------//
		If ExistBlock("UTPDVRCF")
            U_SetMsgRod("IMPRIMINDO CARTA FRETE...")
			U_UTPDVRCF()
		EndIf
        
        U_SetMsgRod("IMPRESSAO DO DANFE CONCLUIDA!")
    EndIf

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} ValidDoc
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function ValidDoc()

    Local lRet := .T.
    Local cBkpDoc := cDocumNf

    If !Empty(cDocumNf) .And. !Empty(cSerieNf)

        SL1->(DbSetOrder(2)) // L1_FILIAL+L1_SERIE+L1_DOC+L1_PDV
        SL1->(DbSeek(xFilial("SL1")+cSerieNf+cDocumNf))

        If SL1->(EOF())
            cDocumNf := PadL(AllTrim(cDocumNf),TamSX3("F2_DOC")[1],"0")
            SL1->(DbSeek(xFilial("SL1")+cSerieNf+cDocumNf))
        EndIf

        If SL1->(EOF())
            lRet := .F.
            cDocumNf := cBkpDoc
            U_SetMsgRod("Serie/Documento não localizado neste PDV...")
        Else
            U_SetMsgRod("")
        EndIf
    EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} SitCanc
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function SitCanc(cDocumNf,cSerieNf)
Local lRet 		:= .T.	//indica se o cancelamento pode continuar
//Local cSerieNf	:= ""	//numero de Série (LG_SERIE)

Local cPDV		:= ""	//numero do PDV ( LG_PDV )
Local lDSitDoc	:= FindFunction("STDSitDoc")	//retorna o L1_SITUA do documento fiscal
Local aSitua	:= {}
Local nSpedExc  := SuperGetMV("MV_SPEDEXC",, 72) // Indica a quantidade de horas q a NFe pode ser cancelada
Local nNfceExc  := SuperGetMV("MV_NFCEEXC",, 0)  // Indica a quantidade de horas q a NFCe pode ser cancelada
Local aCancel	:= STIGetCancel() //Retornar o array com as informacoes da venda a ser cancelada
Local lDocNf	:= .F.  //Indica se a venda que esta sendo cancelada eh nao fiscal

Default cDocumNf := ""
Default cSerieNf := STFGetStation("SERIE")

//cSerieNf := STFGetStation("SERIE")
cPDV := STFGetStation("PDV")

//Tratamento para manter o legado do parametro MV_SPEDEXC 
If nNfceExc <= 0
    nNfceExc := nSpedExc
EndIf 

//se nao estiver compilado, nao validamos o documento, assim como era antes
If lDSitDoc
	
	If ValType(aCancel) == "A" .AND. Len(aCancel) > 5 .AND. !Empty(aCancel[6])
		//Se entrar no IF, significa que eh uma venda nao fiscal vale credito ou vale presente
		lDocNf := .T.
	EndIf

	//retorna os campos L1_SITUA e L1_STORC
	aSitua := STDSitDoc(cSerieNf, cDocumNf, cPDV, lDocNf)

	If aSitua[1] == "404"
		lRet := .F.
		U_SetMsgRod("Documento fiscal não encontrado")
	
	//A - caso de nota cancelada automaticamente | C - cancelamento manual
	ElseIf aSitua[2] $ "A|C"
		lRet := .F.
		If !lDocNf
			U_SetMsgRod("Documento fiscal já enviado para cancelamento")
		Else
			U_SetMsgRod("Documento não fiscal já enviado para cancelamento")
		EndIf
		
	//ElseIf !lDocNf .AND. !STBCancTime(nNfceExc, cDocumNf) //verifica o prazo do documento antes de prosseguir com a exclusao
	//   lRet := .F.
	//   U_SetMsgRod("Prazo para o cancelamento de venda é de" + " " + AllTrim(STR(nNfceExc)) + "horas. Verifique o parâmetro MV_NFCEEXC")
	   
	ElseIf aSitua[1] $ "00|TX" 
		lRet := .T.
	
	Else
		U_SetMsgRod("Venda não finalizada/cancelada. Por favor, verifique a venda.")
		lRet := .F.
	EndIf
	
EndIf

Return lRet
