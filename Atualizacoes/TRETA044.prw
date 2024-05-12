#include "protheus.ch"

/*/{Protheus.doc} TRET043A
Funcao para contabilizacao da troca de sacado.

@author Guilherme Sampaio
@since 11/07/2016
@version 1.0

@return ${return}, ${return_description}

@param nTipo, numeric, descricao
@param nTipCTB, numeric, descricao
@param lHeader, logical, descricao
@param lCtbFat, logical, descricao
@param lCtbFin, logical, descricao
@param nHdlPrv, numeric, descricao
@param nTotalCtb, numeric, descricao
@param cArquivo, characters, descricao
@param dDtSalva, date, descricao
@param dDtCTB, date, descricao
@param cCliAnt, characters, descricao
@param cLojAnt, characters, descricao
@param cRotina, characters, descricao

@type function
/*/
User Function TRETA044(nTipo,nTipCTB,lHeader,lCtbFat,lCtbFin,nHdlPrv,nTotalCtb,cArquivo,dDtSalva,dDtCTB,cCliAnt,cLojAnt,cRotina)

    Local aArea			:= GetArea()
    Local aAreaSE1		:= SE1->(GetArea())
    Local aAreaSF2		:= SF2->(GetArea())
    Local aAreaSD2		:= SD2->(GetArea())
    Local aAreaSA1		:= SA1->(GetArea())
    Local aAreaSED		:= SED->(GetArea())
    Local aAreaSF4		:= SF4->(GetArea())

    Local dMVDtMax		:= SuperGetMV("MV_XDTMAX",,"20010101")	 // Parametro com a Data Maxima retroativa para troca de sacado - Sampaio 11/07/2016
    Local dMVDatafis	:= SuperGetMV("MV_DATAFIS",,"20010101")	 // Parametro com a Data do fechamento fiscal - Sampaio 11/07/2016
    Local dMVDataFin	:= SuperGetMV("MV_DATAFIN",,"20010101")  // Parametro com a Data do fechamento financeiro - Sampaio 11/07/2016
    Local lMVErCtb		:= SuperGetMV("MV_XVERCTB",,.F.) // Parametro para exibir tela de contabilização - Sampaio 11/07/2016
    Local lLancCtb  	:= lMVErCtb						 // Variavel logica de contabilizacao - Sampaio 11/07/2016
    Local lAglutina 	:= .T. 							 // Variavel logica de contabilizacao - Sampaio 11/07/2016
    Local lDetProva     := .F.
    Local cLoteCtb		:= "008855"						 // Variavel de lote contabilizacao : 008855 - Sampaio 11/07/2016
    Local cPadraoFat	:= "180"						 // Lancamento Padrao do Faturamento - Sampaio 11/07/2016
    Local cPadraoFin	:= "182"						 // Lancamento Padrao do Financeiro - Sampaio 11/07/2016
    Local lRet 			:= .T.

    Default nTipo 		:= 0
    Default nTipCTB		:= 0
    Default lHeader		:= .F.
    Default lCtbFat		:= .F.
    Default lCtbFin		:= .F.
    Default nHdlPrv		:= 0
    Default nTotalCtb	:= 0
    Default cArquivo	:= ""
    Default dDtSalva	:= StoD("")
    Default dDtCTB		:= StoD("")
    Default	cCliAnt		:= ""
    Default cLojAnt		:= ""
    Default cRotina		:= ""

    //Pega o cliente e loja anterior - Sampaio 11/07/2016
    If Empty(AllTrim(cCliAnt)) .And. Empty(AllTrim(cLojAnt))
        If nTipo == 1
            cCliAnt := SF2->F2_CLIENTE
            cLojAnt	:= SF2->F2_LOJA
        ElseIf nTipo == 2
            cCliAnt	:= SE1->E1_CLIENTE
            cLojAnt	:= SE1->E1_LOJA
        EndIf
    EndIf

    Do Case
        Case nTipo == 1 .And. nTipCTB == 1 // Faturamento
            
            If !Empty(SF2->F2_DTLANC) .And. SF2->F2_DTLANC <= dMVDtMax	  // Nova validacao baseada no parametro MV_XDTMAX - Sampaio 11/07/2016
                lRet := .F.
            ElseIf !Empty(SF2->F2_DTLANC) .And. SF2->F2_DTLANC > dMVDtMax // Movimento contabilizado e com data posterior a data maxima - Sampaio 11/07/2016
                lCtbFat := .T.
            Endif
            
            // Caso não possa prosseguir passo para o próximo registro
            If !lRet
                Return lRet
            EndIf
            
            // Verifica se o movimento esta contabilizado e com data posterior a data maxima - Sampaio 11/07/2016
            If lCtbFat .And. SF2->F2_EMISSAO <= dMVDatafis
                
                // Salvo a dDataBase do Sistema - Sampaio 11/07/2016
                dDtSalva 	:= dDataBase
                
            ElseIf lCtbFat .And. SF2->F2_EMISSAO > dMVDatafis
                
                // Salvo a dDataBase do Sistema - Sampaio 11/07/2016
                dDtSalva 	:= dDataBase
                
                // Peda a data da contabilizacao - Sampaio 11/07/2016
                dDataBase 	:= SF2->F2_EMISSAO
                
            EndIf
            
            // Pega a data da contabilizacao para o LOG
            If !Empty(dDtSalva)
                dDtCTB  := dDataBase
            Else
                dDtCTB	:= StoD("")
            EndIf
            
            // Verifica se chamo a tela de contabilizacao - Sampaio 11/07/2016
            
            If nTotalCtb > 0 .And. nHdlPrv == 0
                nTotalCtb := 0
                
                // Chama a integracao com o contabil - Sampaio 11/07/2016
                cA100Incl(cArquivo,nHdlPrv,3,cLoteCtb,lLancCtb,lAglutina)
                
                nTotalCtb := 0
                lHeader   := .F.
                
            EndIf
            
            //HeadProva
            If !lHeader .And. nHdlPrv == 0
                nHdlPrv:=HeadProva(cLoteCtb,cRotina,Substr(cUsuario,7,6),@cArquivo)
                
                If nHdlPrv <= 0
                    HELP(" ",1,"SEM_LANC")
                    lHeader := .F.
                Else
                    lHeader := .T.
                EndIf
                
            EndIf
            
        Case nTipo == 2 .And. nTipCTB == 1 // Financeiro
            
            // Nova validacao, verifico se o E1_LA está diferente de vazio,
            // se o conteudo for igual a "S" e a emissao for menor/igual que o parametro MV_XDTMAX
            If !Empty(SE1->E1_LA) .And. AllTrim(SE1->E1_LA) == "S" .And. SE1->E1_EMISSAO <= dMVDtMax
                lRet := .F.
                // se o conteudo for igual a "S" e a emissao for maior que o parametro MV_XDTMAX
            ElseIf !Empty(SE1->E1_LA) .And. AllTrim(SE1->E1_LA) == "S" .And. SE1->E1_EMISSAO > dMVDtMax
                lCtbFin := .T.
            Endif
            
            If SE1->E1_TIPO='R$' .And. !lCtbFin
                // posiciona na tabela de SE5
                cFilTit:=xFilial('SE5')
                SE5->(DbSetOrder(7), DbGoTop(), DbSeek(cFilTit+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)))
                
                If  !Empty(SE5->E5_LA) .And. AllTrim(SE5->E5_LA) == "S" .And. SE5->E5_DATA <= dMVDtMax
                    lRet := .F.
                    // se o conteudo for igual a "S" e a emissao for maior que o parametro MV_XDTMAX
                ElseIf  !Empty(SE5->E5_LA) .And. AllTrim(SE5->E5_LA) == "S" .And. SE5->E5_DATA > dMVDtMax
                    lCtbFin := .T.
                Endif
            Endif
            
            // Caso não possa prosseguir passo para o próximo registro
            If !lRet
                Return lRet
            EndIf
            
            // Verifico se a data de emissao do titulo é menor que a data do fechamento financeiro
            If lCtbFin .And. SE1->E1_EMISSAO <= dMVDataFin
                
                // Salvo a dDataBase do Sistema - Sampaio 11/07/2016
                dDtSalva 	:= dDataBase
                
            ElseIf lCtbFin .And. SE1->E1_EMISSAO > dMVDataFin
                
                // Salvo a dDataBase do Sistema - Sampaio 11/07/2016
                dDtSalva 	:= dDataBase
                
                // Peda a data da contabilizacao - Sampaio 11/07/2016
                dDataBase 	:= SE1->E1_EMISSAO
                
            EndIf
            
            // Pega a data da contabilizacao para o LOG
            If !Empty(dDtSalva)
                dDtCTB  := dDataBase
            Else
                dDtCTB	:= StoD("")
            EndIf
            
            // Verifica se chamo a tela de contabilizacao - Sampaio 11/07/2016
            
            If nTotalCtb > 0 .And. nHdlPrv == 0
                nTotalCtb := 0
                
                // Chama a integracao com o contabil - Sampaio 11/07/2016
                cA100Incl(cArquivo,nHdlPrv,3,cLoteCtb,lLancCtb,lAglutina)
                
                nTotalCtb := 0
                lHeader   := .F.
                
            EndIf
            
            //HeadProva
            If !lHeader .And. nHdlPrv == 0
                nHdlPrv:=HeadProva(cLoteCtb,cRotina,Substr(cUsuario,7,6),@cArquivo)
                
                If nHdlPrv <= 0
                    HELP(" ",1,"SEM_LANC")
                    lHeader := .F.
                Else
                    lHeader := .T.
                EndIf
                
            EndIf
            
        Case nTipo == 1 .And. nTipCTB == 2 // Faturamento
            
            If lHeader .And. lCtbFat
                
                // posiciona na tabela de clientes
                SA1->(DbSetOrder(1))
                SA1->(DbSeek(xFilial("SA1")+SD2->D2_CLIENTE+SD2->D2_LOJA))
                
                // posiciona na tabela de TES
                SF4->(DbSetOrder(1))
                SF4->(DbSeek(xFilial("SF4")+SD2->D2_TES))
                
                //DetProva
                lDetProva 	:= .T.
                nParcCtb  	:= DetProva(nHdlPrv,cPadraoFat,cRotina,cLoteCtb)
                
                nTotalCtb += nParcCtb
                
            Endif
            
        Case nTipo == 2 .And. nTipCTB == 2 // Financeiro
            
            If lHeader .And. lCtbFin
                
                // posiciona na tabela de clientes
                SA1->(DbSetOrder(1))
                SA1->(DbSeek(xFilial("SA1")+SE1->(E1_CLIENTE+E1_LOJA)))
                
                // posiciona na tabela de naturezas
                SED->(DbSetOrder(1))
                SED->(DbSeek(xFilial("SED")+SE1->E1_NATUREZ))
                
                // posiciona na tabela de SE5
                cFilTit:=xFilial('SE5')
                SE5->(DbSetOrder(7), DbGoTop(), DbSeek(cFilTit+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)))
                
                //DetProva
                lDetProva 	:= .T.
                nParcCtb  	:= DetProva(nHdlPrv,cPadraoFin,cRotina,cLoteCtb)
                
                nTotalCtb += nParcCtb
                
            EndIf
            
        Case nTipo == 3     // Fecha o Lote Contabil
            
            if lHeader //RodaProva
                
                RodaProva(nHdlPrv,nTotalCtb)
                
                if nTotalCtb > 0
                    nTotalCtb := 0
                    cA100Incl(cArquivo,nHdlPrv,3,cLoteCtb,lLancCtb,lAglutina)
                endIf
                
                // Volta para a data original - Sampaio 12/07/2016
                if !empty(dDtSalva)
                    dDataBase := dDtSalva
                endif
                
                nHdlPrv := 0
            endif
            
    EndCase

    RestArea(aArea)
    RestArea(aAreaSE1)
    RestArea(aAreaSF2)
    RestArea(aAreaSD2)
    RestArea(aAreaSA1)
    RestArea(aAreaSED)
    RestArea(aAreaSF4)

Return lRet
