#include "protheus.ch"
#include "topconn.ch"
#Include "TBICONN.CH"

#Define CSS_BTNAZUL " QPushButton { color: #FFFFFF; font-weight:bold; "+;
	"    background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #3AAECB, stop: 1 #0F9CBF); "+;
	"    border:1px solid #369CB5; "+;
	"    border-radius: 3px; } "+;
	" QPushButton:pressed { "+;
	"    background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #148AA8, stop: 1 #39ACC9); "+;
	"    border:1px solid #369CB5; }";

/*/{Protheus.doc} User Function TRETE047
Tela de Prévia da Fatura
@type  Function
@author danilo
@since 28/09/2023
@version 1
/*/
User Function TRETE047(aSizeAut,aPosObj)

    Local nI, nJ
    Local cTitulo 		:= "Faturamento Manual V2 - Prévia da Fatura"
    Local oBtn1, oBtn2
    Local lConfirma := .F.
    Local bMarcaTodos := {|x| iif(x[1]=="LBNO", x[1]:="LBOK", x[1]:="LBNO")  }
    
	Local aHeaderEx := {}
	Local aColsEx := {}
    Private aT47Campos := {"MARK","E1_FILIAL","E1_FILORIG","E1_ORIGEM","E1_CLIENTE","E1_LOJA","A1_NOME","E1_XCGCEMI","A1_XCLASSE","E1_VENCTO","E1_VALOR","E1_VLRREAL","U57_MOTIVO"}
    Private nPosInfoAd := len(aT47Campos)+1

    Private oGridDet
    Private lMARKALL := .F.

    Private __XVEZ 		:= "0"
    Private __ASC       := .T.

    Private oChkFat
    Private lChkFat := .F.

    Private lMVVFilOri	:= len(cFilAnt) <> len(AlltriM(xFilial("SE1"))) //SuperGetMV("MV_XFILORI", .F., .F.)
    Private nPosFilial	:= U_TRE017CP(5,"nPosFilial")
	Private nPosFilOri	:= U_TRE017CP(5,"nPosFilOri")
    Private nPosTipo 	:= U_TRE017CP(5,"nPosTipo")
	Private nPosPrefixo	:= U_TRE017CP(5,"nPosPrefixo")
	Private nPosNumero	:= U_TRE017CP(5,"nPosNumero")
	Private nPosCliente	:= U_TRE017CP(5,"nPosCliente")
	Private nPosLoja	:= U_TRE017CP(5,"nPosLoja")
	Private nPosNome	:= U_TRE017CP(5,"nPosNome")
	Private nPosCGC	    := U_TRE017CP(5,"nPosCGC")
	Private nPosClasse	:= U_TRE017CP(5,"nPosClasse")
    Private nPosSaldo	:= U_TRE017CP(5,"nPosSaldo")
    Private nPosAcresc	:= U_TRE017CP(5,"nPosAcresc")
    Private nPosDecres	:= U_TRE017CP(5,"nPosDecres")
    Private nPosVlAcess	:= U_TRE017CP(5,"nPosVlAcess")
    Private nPosValor	:= U_TRE017CP(5,"nPosValor")
    Private nPosMotiv	:= U_TRE017CP(5,"nPosMotiv")
	Private nPosProdOs	:= U_TRE017CP(5,"nPosProdOs")
    Private nPosRecno	:= U_TRE017CP(5,"nPosRecno")
    Private nPosVencto	:= U_TRE017CP(5,"nPosVencto")
    Private nPosObsFat	:= U_TRE017CP(5,"nPosObsFat")
	
    Static oDlgT047

    if nPosObsFat <> Nil .AND. nPosObsFat > 0 
        nX := aScan(aT47Campos,"A1_XCLASSE")
        aadd(aT47Campos,Nil)
        aIns(aT47Campos,nX)
        aT47Campos[nX] := "E1_NOMCLI" //colocado esse campo para mostrar parte da informação 
        nPosInfoAd++
    endif

    DEFINE MSDIALOG oDlgT047 TITLE cTitulo From aSizeAut[7],0 TO aSizeAut[6]-100,aSizeAut[5]-60 OF oMainWnd PIXEL
    
    aHeaderEx := U_MontaHeader( aT47Campos)
    aHeaderEx[aScan( aT47Campos,"E1_ORIGEM")][1] := "Origem Fatura"
    aHeaderEx[aScan( aT47Campos,"E1_ORIGEM")][4] := 15
    aHeaderEx[aScan( aT47Campos,"E1_XCGCEMI")][1] := "CNPJ/CPF"
    aHeaderEx[aScan( aT47Campos,"E1_XCGCEMI")][4] := 18
    aHeaderEx[aScan( aT47Campos,"E1_VALOR")][1] := "Vlr.Fatura"
    aHeaderEx[aScan( aT47Campos,"E1_VLRREAL")][1] := "Vlr.Bruto"
    aHeaderEx[aScan( aT47Campos,"U57_MOTIVO")][1] := "Mot.Saque"
    if nPosObsFat <> Nil .AND. nPosObsFat > 0 
        aHeaderEx[aScan( aT47Campos,"E1_NOMCLI")][1] := "Obs.Faturamento"
    endif
    
    aadd(aColsEx, U_MontaDados("SE1", aT47Campos, .T.,,,.T.))
	oGridDet := MsNewGetDados():New( aPosObj[1,1] - 30,aPosObj[1,2],aPosObj[1,3] - 50,aPosObj[1,4] - 27,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oDlgT047, aHeaderEx, aColsEx)
    oGridDet:oBrowse:bLDblClick := {|| MarkReg()  }
	oGridDet:oBrowse:bHeaderClick := {|oBrw,nCol| iif(nCol > 1, U_UOrdGrid(@oGridDet, @nCol), iif(lMARKALL .AND. !empty(oGridDet:aCols[1][2]), (aEval(oGridDet:aCols, bMarcaTodos),oBrw:Refresh(),oBrw:SetFocus(),lMARKALL:=!lMARKALL), lMARKALL:=!lMARKALL) )}
    
    @ aPosObj[1,3] - 47,aPosObj[1,2]+5 CHECKBOX oChkFat VAR lChkFat PROMPT "Desconsiderar titulos de Fatura"  Size 100, 007 PIXEL OF oDlgT047 COLORS 0, 16777215 PIXEL
	oChkFat:bChange := ({|| FWMsgRun(,{|oSay| LoadFatura(oSay)},'Aguarde','carregando dados...') })

    @ aPosObj[1,3] - 47, aPosObj[1,4] - 75 BUTTON oBtn1 PROMPT "Confirmar" SIZE 040, 013 OF oDlgT047 ACTION (lConfirma := .T.,oDlgT047:End()) PIXEL
    oBtn1:SetCSS( CSS_BTNAZUL )
    @ aPosObj[1,3] - 47, aPosObj[1,4] - 120 BUTTON oBtn2 PROMPT "Fechar" SIZE 040, 013 OF oDlgT047 ACTION oDlgT047:End() PIXEL

    ACTIVATE MSDIALOG oDlgT047 CENTERED ON INIT FWMsgRun(,{|oSay| LoadFatura(oSay)},'Aguarde','carregando dados...')

    if lConfirma
        //variaveis private em TRETE017
        nCont		:= 0
        nTotBrut  	:= 0
        nTotLiq  	:= 0
        For nJ := 1 to len(oGridDet:aCols)
            //aReg é private em TRETE017
            For nI := 1 To Len(aReg)
                if aScan(oGridDet:aCols[nJ][nPosInfoAd], aReg[nI][nPosRecno]) > 0
                    aReg[nI][1] := oGridDet:aCols[nJ][1] == "LBOK" //marco registro

                    if aReg[nI][1]
                        nCont++
                        If Val(StrTran(StrTran(aReg[nI][nPosValor],".",""),",",".")) > 0
                            nTotBrut += Val(StrTran(StrTran(aReg[nI][nPosValor],".",""),",","."))
                        Endif

                        If Val(StrTran(StrTran(aReg[nI][nPosSaldo],".",""),",",".")) > 0
                            nTotLiq += Val(StrTran(StrTran(aReg[nI][nPosSaldo],".",""),",","."))
                        Endif
                    endif
                endif
            next nI
        Next nJ
    endif

Return 

Static Function MarkReg()

    if nPosObsFat <> Nil .AND. nPosObsFat > 0 .AND. oGridDet:oBrowse:nColPos == aScan(aT47Campos,"E1_NOMCLI") .AND. !empty(oGridDet:aCols[oGridDet:nAt][aScan(aT47Campos,"E1_NOMCLI")])
		ObsCliente(oGridDet:aCols[oGridDet:nAt][aScan(aT47Campos,"E1_CLIENTE")],oGridDet:aCols[oGridDet:nAt][aScan(aT47Campos,"E1_LOJA")])
		Return
	endif

    oGridDet:aCols[oGridDet:nAt][1] := iif(oGridDet:aCols[oGridDet:nAt][1]=="LBNO", iif(!empty(oGridDet:aCols[oGridDet:nAt][2]),"LBOK","LBNO"), "LBNO") 
    oGridDet:oBrowse:Refresh()

Return

Static Function LoadFatura(oSay)
    
    Local nI, nJ, nK, nL, nM
    Local lFatConv 	:= SuperGetMv("MV_XFTCONV",,.F.) //define se abrira modo faturamento conveniencia

    Local aCliente		:= {}
	Local aGrpProd 		:= {}
	Local aProd			:= {}
    Local aTit			:= {}
    Local aLinTmp       := {}

    Local lRestGrp 	    := .F.
    Local lRestPrd 	    := .F.
    Local lSepFpg		:= .F.
    Local lSepMot		:= .F.
    Local lSepOrd		:= .F.

    Local aTmpCli 		:= {}
	Local aTmpSepFp		:= {}
	Local aTmpSepMt		:= {}
	Local aTmpSepOs		:= {}
	Local aTmpGrp		:= {}
	Local aTmpProd		:= {}

    Local lAchou        := .F.
    Local cGrpOri       := ""
    Local cGrpDes       := ""
    Local cProdOri      := ""
    Local cProdDes      := ""

    Local dDtVenc       := CToD("")
    Local nDiasVenc		:= SuperGetMv("MV_XDIASVC",.F.,1)
    Local nSldTit		:= 0
    Local nVlrTit 		:= 0

    Local lFatNatOr		:= SuperGetMv("MV_XFTNATO",,.F.) //define se a fatura irá assuimir a mesma natureza dos titulos origem

    If empty(aReg[1][nPosNumero]) //não há dados a mostrar
		Return
	Endif

    oGridDet:aCols := {}

    //aReg é private em TRETE017
    For nI := 1 To Len(aReg)

        lRestGrp 	:= .F.
        lRestPrd 	:= .F.
        lSepFpg		:= .F.
        lSepMot		:= .F.
        lSepOrd		:= .F.

        SE1->(DbGoTo(aReg[nI][nPosRecno]))

        If SE1->E1_SALDO == 0 // Título baixado
            LOOP
        Endif

        If SE1->E1_SITUACA == "1" // Cob. simples (Borderô)
            LOOP
        endif

        // Individualiza clientes
        If Len(aCliente) > 0
            If aScan(aCliente,{|x| x[1] == aReg[nI][nPosCliente] .And. x[2] == aReg[nI][nPosLoja]}) == 0
                AAdd(aCliente,{aReg[nI][nPosCliente],aReg[nI][nPosLoja]})
            Endif
        Else
            AAdd(aCliente,{aReg[nI][nPosCliente],aReg[nI][nPosLoja]})
        Endif

        if AllTrim(aReg[nI][nPosTipo]) == "FT"

            if lChkFat
                LOOP
            endif
            
            AAdd(aTit,{aReg[nI],;
                        lSepFpg,;  //Separação por [Forma de Pagamento]
                        lSepMot,;  //Separação por [Motivo de Saque]
                        lSepOrd,;  //Separação por [Ordem de Serviço]
                        lRestGrp,; //Restrição por [Grupo de Produto]
                        lRestPrd}) //Restrição por [Produto]

        else

            // Características de Faturamento
            If SA1->(DbSeek(xFilial("SA1")+aReg[nI][nPosCliente]+aReg[nI][nPosLoja]))

                // Validação quanto a restrição de Grupos de Produto/Produtos
                If !Empty(SA1->A1_XRESTGP) .And. IIF(SA1->(FieldPos("A1_XNSEPAR") > 0),SA1->A1_XNSEPAR <> "S",.T.) //Possui restrição e não desconsidera a restrição para separação de faturas
                    aGrpProd := StrTokArr(AllTrim(SA1->A1_XRESTGP),"/")
                Endif

                If!Empty(SA1->A1_XRESTPR) .And. IIF(SA1->(FieldPos("A1_XNSEPAR") > 0),SA1->A1_XNSEPAR <> "S",.T.) //Possui restrição e não desconsidera a restrição para separação de faturas
                    aProd := StrTokArr(AllTrim(SA1->A1_XRESTPR),"/")
                Endif

                // Verifica Separações
                if lFatNatOr
                    lSepFpg := .T.
                else
                    If SA1->A1_XSEPFPG == "S" //Individualiza fatura por forma de pagamento
                        lSepFpg := .T.
                    Else
                        lSepFpg := .F.
                    Endif
                endif

                If !lFatConv // Diferente de conveniência
                    If SA1->A1_XSEPMOT == "S" //Individualiza fatura por Motivo de saque
                        lSepMot := .T.
                    Else
                        lSepMot := .F.
                    Endif

                    If SA1->A1_XSEPORD == "S" //Individualiza fatura por Ordem de serviço
                        lSepOrd := .T.
                    Else
                        lSepOrd := .F.
                    Endif
                EndIf
                
            Endif

            // Restrição quanto ao Grupo de Produto
            SD2->(DbSetOrder(3)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
            SD2->(DbGoTop())
            SB1->(DbSetOrder(1)) // B1_FILIAL+B1_COD
            SB1->(DbGoTop())
            If SD2->(DbSeek(xFilial("SD2",aReg[nI][iif(lMVVFilOri,nPosFilOri,nPosFilial)])+aReg[nI][nPosNumero]+aReg[nI][nPosPrefixo]+aReg[nI][nPosCliente]+aReg[nI][nPosLoja])) //Exclusivo
                While SD2->(!EOF()) .And. SD2->D2_FILIAL == xFilial("SD2",aReg[nI][iif(lMVVFilOri,nPosFilOri,nPosFilial)]) .And. SD2->D2_DOC == aReg[nI][nPosNumero] .And.;
                        SD2->D2_SERIE == aReg[nI][nPosPrefixo] .And. SD2->D2_CLIENTE == aReg[nI][nPosCliente] .And. SD2->D2_LOJA == aReg[nI][nPosLoja]

                    If SB1->(DbSeek(xFilial("SB1")+SD2->D2_COD))
                        If aScan(aGrpProd,{|x| x == SB1->B1_GRUPO}) > 0
                            lRestGrp := .T.
                            Exit
                        Endif
                    Endif

                    SD2->(DbSkip())
                EndDo
            Endif

            // Restrição quanto ao Produto
            SD2->(DbSetOrder(3)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
            SD2->(DbGoTop())
            If SD2->(DbSeek(xFilial("SD2",aReg[nI][iif(lMVVFilOri,nPosFilOri,nPosFilial)])+aReg[nI][nPosNumero]+aReg[nI][nPosPrefixo]+aReg[nI][nPosCliente]+aReg[nI][nPosLoja]))
                While SD2->(!EOF()) .And. SD2->D2_FILIAL == xFilial("SD2",aReg[nI][iif(lMVVFilOri,nPosFilOri,nPosFilial)]) .And. SD2->D2_DOC == aReg[nI][nPosNumero] .And.;
                        SD2->D2_SERIE == aReg[nI][nPosPrefixo] .And. SD2->D2_CLIENTE == aReg[nI][nPosCliente] .And. SD2->D2_LOJA == aReg[nI][nPosLoja]

                    If SB1->(DbSeek(xFilial("SB1")+SD2->D2_COD))
                        If aScan(aProd,{|x| AllTrim(x) == AllTrim(SD2->D2_COD)}) > 0
                            lRestPrd := .T.
                            Exit
                        Endif
                    Endif

                    SD2->(DbSkip())
                EndDo
            Endif

            If !lFatConv // Diferente de conveniência
                lSepMot := lSepMot .And. !Empty(aReg[nI][nPosMotiv]) //Separa [Motivo de Saque] e possui informação de saque
                lSepOrd := lSepOrd .And. !Empty(aReg[nI][nPosProdOs]) //Separa [Ordem de Serviço] e possui ordem de serviço
            EndIf
            lRestGrp := lRestGrp .And. !(AllTrim(aReg[nI][nPosTipo]) == "RP" .Or. AllTrim(aReg[nI][nPosTipo]) == "VLS") //Há restrição por [Grupo de Produto] e não se trata de um agrupamento de requisições ou vale
            lRestPrd := lRestPrd .And. !(AllTrim(aReg[nI][nPosTipo]) == "RP" .Or. AllTrim(aReg[nI][nPosTipo]) == "VLS") //Há restrição por [Produto] e não se trata de um agrupamento de requisições ou vale

            AAdd(aTit,{aReg[nI],;
                        lSepFpg,;  //Separação por [Forma de Pagamento]
                        lSepMot,;  //Separação por [Motivo de Saque]
                        lSepOrd,;  //Separação por [Ordem de Serviço]
                        lRestGrp,; //Restrição por [Grupo de Produto]
                        lRestPrd}) //Restrição por [Produto]
        endif

    next nI

    For nI := 1 To Len(aCliente)

        aTmpCli 	:= {}
        aTmpSepFp	:= {}
        aTmpSepMt	:= {}
        aTmpSepOs	:= {}
        aTmpGrp		:= {}
        aTmpProd	:= {}

        // Agrupa os títulos por cliente
        For nJ := 1 To Len(aTit)

            If aCliente[nI][1] == aTit[nJ][1][nPosCliente] .And. aCliente[nI][2] == aTit[nJ][1][nPosLoja]
                If Len(aTmpCli) > 0
                    lAchou :=  .F.

                    For nK := 1 To Len(aTmpCli)
                        For nL := 1 To Len(aTmpCli[nK][1])

                            If aCliente[nI][1] == aTmpCli[nK][1][nL][nPosCliente] .And. aCliente[nI][2] == aTmpCli[nK][1][nL][nPosLoja] ;
                                    .And. aTmpCli[nK][2] == aTit[nJ][2] ; //lSepFpg
                                    .And. aTmpCli[nK][3] == aTit[nJ][3] ; //lSepMot
                                    .And. aTmpCli[nK][4] == aTit[nJ][4] ; //lSepOrd
                                    .And. aTmpCli[nK][5] == aTit[nJ][5] ; //lRestGrp
                                    .And. aTmpCli[nK][6] == aTit[nJ][6]	  //lRestPrd

                                lAchou := .T.
                                AAdd(aTmpCli[nK][1],aTit[nJ][1])
                                Exit
                            Endif
                        Next nL

                        If lAchou
                            Exit
                        Endif
                    Next nK

                    If !lAchou
                        AAdd(aTmpCli,{{aTit[nJ][1]},aTit[nJ][2],aTit[nJ][3],aTit[nJ][4],aTit[nJ][5],aTit[nJ][6]})
                    Endif
                Else
                    AAdd(aTmpCli,{{aTit[nJ][1]},aTit[nJ][2],aTit[nJ][3],aTit[nJ][4],aTit[nJ][5],aTit[nJ][6]})
                Endif
            Endif
        Next nJ

        // Não há títulos relacionados ao cliente posicionado
        If Len(aTmpCli) == 0
            Loop
        Endif

        // Verifica se há separação por forma de pagamento
        For nJ := 1 To Len(aTmpCli)
            If aTmpCli[nJ][2] // Separa forma de pagamento
                For nK := 1 To Len(aTmpCli[nJ][1])
                    If Len(aTmpSepFp) > 0
                        lAchou :=  .F.

                        For nL := 1 To Len(aTmpSepFp)
                            For nM := 1 To Len(aTmpSepFp[nL][1])
                                If aTmpSepFp[nL][1][nM][nPosTipo] == aTmpCli[nJ][1][nK][nPosTipo] ;
                                        .And. aTmpSepFp[nL][2] == aTmpCli[nJ][2] ; //lSepFpg
                                        .And. aTmpSepFp[nL][3] == aTmpCli[nJ][3] ; //lSepMot
                                        .And. aTmpSepFp[nL][4] == aTmpCli[nJ][4] ; //lSepOrd
                                        .And. aTmpSepFp[nL][5] == aTmpCli[nJ][5] ; //lRestGrp
                                        .And. aTmpSepFp[nL][6] == aTmpCli[nJ][6]   //lRestPrd

                                    lAchou := .T.
                                    AAdd(aTmpSepFp[nL][1],aTmpCli[nJ][1][nK])
                                    Exit
                                Endif
                            Next nM

                            If lAchou
                                Exit
                            Endif
                        Next nL

                        If !lAchou
                            AAdd(aTmpSepFp,{{aTmpCli[nJ][1][nK]},aTmpCli[nJ][2],aTmpCli[nJ][3],aTmpCli[nJ][4],aTmpCli[nJ][5],aTmpCli[nJ][6]})
                        Endif
                    Else
                        AAdd(aTmpSepFp,{{aTmpCli[nJ][1][nK]},aTmpCli[nJ][2],aTmpCli[nJ][3],aTmpCli[nJ][4],aTmpCli[nJ][5],aTmpCli[nJ][6]})
                    Endif
                Next nK
            Else
                AAdd(aTmpSepFp,{aTmpCli[nJ][1],aTmpCli[nJ][2],aTmpCli[nJ][3],aTmpCli[nJ][4],aTmpCli[nJ][5],aTmpCli[nJ][6]})
            Endif
        Next nJ

        // Verifica se há separação por motivo de saque
        For nJ := 1 To Len(aTmpSepFp)
            If aTmpSepFp[nJ][3] // Separa motivo de saque e possui informação de saque
                For nK := 1 To Len(aTmpSepFp[nJ][1])
                    If Len(aTmpSepMt) > 0
                        lAchou :=  .F.

                        For nL := 1 To Len(aTmpSepMt)
                            For nM := 1 To Len(aTmpSepMt[nL][1])
                                If aTmpSepMt[nL][1][nM][nPosMotiv] == aTmpSepFp[nJ][1][nK][nPosMotiv] ;
                                        .And. !Empty(aTmpSepMt[nL][1][nM][nPosMotiv]) ;
                                        .And. !Empty(aTmpSepFp[nJ][1][nK][nPosMotiv]) ;
                                        .And. aTmpSepMt[nL][2] == aTmpSepFp[nJ][2] ; //lSepFpg
                                        .And. aTmpSepMt[nL][3] == aTmpSepFp[nJ][3] ; //lSepMot
                                        .And. aTmpSepMt[nL][4] == aTmpSepFp[nJ][4] ; //lSepOrd
                                        .And. aTmpSepMt[nL][5] == aTmpSepFp[nJ][5] ; //lRestGrp
                                        .And. aTmpSepMt[nL][6] == aTmpSepFp[nJ][6]   //lRestPrd

                                    lAchou := .T.
                                    AAdd(aTmpSepMt[nL][1],aTmpSepFp[nJ][1][nK])
                                    Exit
                                Endif
                            Next nM

                            If lAchou
                                Exit
                            Endif
                        Next nL

                        If !lAchou
                            AAdd(aTmpSepMt,{{aTmpSepFp[nJ][1][nK]},aTmpSepFp[nJ][2],aTmpSepFp[nJ][3],aTmpSepFp[nJ][4],aTmpSepFp[nJ][5],aTmpSepFp[nJ][6]})
                        Endif
                    Else
                        AAdd(aTmpSepMt,{{aTmpSepFp[nJ][1][nK]},aTmpSepFp[nJ][2],aTmpSepFp[nJ][3],aTmpSepFp[nJ][4],aTmpSepFp[nJ][5],aTmpSepFp[nJ][6]})
                    Endif
                Next nK
            Else
                AAdd(aTmpSepMt,{aTmpSepFp[nJ][1],aTmpSepFp[nJ][2],aTmpSepFp[nJ][3],aTmpSepFp[nJ][4],aTmpSepFp[nJ][5],aTmpSepFp[nJ][6]})
            Endif
        Next nJ

        // Verifica se há separação por ordem de serviço
        For nJ := 1 To Len(aTmpSepMt)
            If aTmpSepMt[nJ][4] // Separa ordem de serviço e possui ordem de serviço

                For nK := 1 To Len(aTmpSepMt[nJ][1])
                    If Len(aTmpSepOs) > 0
                        lAchou :=  .F.

                        For nL := 1 To Len(aTmpSepOs)
                            For nM := 1 To Len(aTmpSepOs[nL][1])
                                If aTmpSepOs[nL][1][nM][nPosProdOs] == aTmpSepMt[nJ][1][nK][nPosProdOs] ;
                                        .And. !Empty(aTmpSepOs[nL][1][nM][nPosProdOs]) ;
                                        .And. !Empty(aTmpSepMt[nJ][1][nK][nPosProdOs]) ;
                                        .And. aTmpSepOs[nL][2] == aTmpSepMt[nJ][2] ; //lSepFpg
                                    .And. aTmpSepOs[nL][3] == aTmpSepMt[nJ][3] ; //lSepMot
                                    .And. aTmpSepOs[nL][4] == aTmpSepMt[nJ][4] ; //lSepOrd
                                    .And. aTmpSepOs[nL][5] == aTmpSepMt[nJ][5] ; //lRestGrp
                                    .And. aTmpSepOs[nL][6] == aTmpSepMt[nJ][6]   //lRestPrd

                                    lAchou := .T.
                                    AAdd(aTmpSepOs[nL][1],aTmpSepMt[nJ][1][nK])
                                    Exit
                                Endif
                            Next nM

                            If lAchou
                                Exit
                            Endif
                        Next nL

                        If !lAchou
                            AAdd(aTmpSepOs,{{aTmpSepMt[nJ][1][nK]},aTmpSepMt[nJ][2],aTmpSepMt[nJ][3],aTmpSepMt[nJ][4],aTmpSepMt[nJ][5],aTmpSepMt[nJ][6]})
                        Endif
                    Else
                        AAdd(aTmpSepOs,{{aTmpSepMt[nJ][1][nK]},aTmpSepMt[nJ][2],aTmpSepMt[nJ][3],aTmpSepMt[nJ][4],aTmpSepMt[nJ][5],aTmpSepMt[nJ][6]})
                    Endif
                Next nK
            Else
                AAdd(aTmpSepOs,{aTmpSepMt[nJ][1],aTmpSepMt[nJ][2],aTmpSepMt[nJ][3],aTmpSepMt[nJ][4],aTmpSepMt[nJ][5],aTmpSepMt[nJ][6]})
            Endif
        Next nJ

        // Verifica se há restrição por Grupo de Produto
        SD2->(DbSetOrder(3)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
        SD2->(DbGoTop())
        SB1->(DbSetOrder(1)) // B1_FILIAL+B1_COD
        SB1->(DbGoTop())
        For nJ := 1 To Len(aTmpSepOs)
            If aTmpSepOs[nJ][5] // Há restrição por Grupo de Produto e não se trata de um agrupamento de requisições ou vale
                For nK := 1 To Len(aTmpSepOs[nJ][1])
                    If Len(aTmpGrp) > 0
                        cGrpOri := ""

                        // Grupo título de origem
                        If SD2->(DbSeek(xFilial("SD2", aTmpSepOs[nJ][1][nK][iif(lMVVFilOri,nPosFilOri,nPosFilial)])+aTmpSepOs[nJ][1][nK][nPosNumero]+aTmpSepOs[nJ][1][nK][nPosPrefixo]+aTmpSepOs[nJ][1][nK][nPosCliente]+aTmpSepOs[nJ][1][nK][nPosLoja])) //Exclusivo
                            If SB1->(DbSeek(xFilial("SB1")+SD2->D2_COD))
                                cGrpOri := SB1->B1_GRUPO
                            Endif
                        Endif

                        lAchou :=  .F.

                        For nL := 1 To Len(aTmpGrp)
                            For nM := 1 To Len(aTmpGrp[nL][1])
                                lAchou :=  .F.
                                cGrpDes := ""

                                If SD2->(DbSeek(xFilial("SD2", aTmpGrp[nL][1][nM][iif(lMVVFilOri,nPosFilOri,nPosFilial)])+aTmpGrp[nL][1][nM][nPosNumero]+aTmpGrp[nL][1][nM][nPosPrefixo]+aTmpGrp[nL][1][nM][nPosCliente]+aTmpGrp[nL][1][nM][nPosLoja])) //Exclusivo
                                    If SB1->(DbSeek(xFilial("SB1")+SD2->D2_COD))
                                        cGrpDest := SB1->B1_GRUPO
                                    Endif
                                Endif

                                If cGrpOri == cGrpDest ;
                                        .And. aTmpGrp[nL][2] == aTmpSepOs[nJ][2] ; //lSepFpg
                                    .And. aTmpGrp[nL][3] == aTmpSepOs[nJ][3] ; //lSepMot
                                    .And. aTmpGrp[nL][4] == aTmpSepOs[nJ][4] ; //lSepOrd
                                    .And. aTmpGrp[nL][5] == aTmpSepOs[nJ][5] ; //lRestGrp
                                    .And. aTmpGrp[nL][6] == aTmpSepOs[nJ][6]   //lRestPrd

                                    lAchou := .T.
                                    AAdd(aTmpGrp[nL][1],aTmpSepOs[nJ][1][nK])
                                    Exit
                                Endif
                            Next nM

                            If lAchou
                                Exit
                            Endif
                        Next nL

                        If !lAchou
                            AAdd(aTmpGrp,{{aTmpSepOs[nJ][1][nK]},aTmpSepOs[nJ][2],aTmpSepOs[nJ][3],aTmpSepOs[nJ][4],aTmpSepOs[nJ][5],aTmpSepOs[nJ][6]})
                        Endif
                    Else
                        AAdd(aTmpGrp,{{aTmpSepOs[nJ][1][nK]},aTmpSepOs[nJ][2],aTmpSepOs[nJ][3],aTmpSepOs[nJ][4],aTmpSepOs[nJ][5],aTmpSepOs[nJ][6]})
                    Endif
                Next nK
            Else
                AAdd(aTmpGrp,{aTmpSepOs[nJ][1],aTmpSepOs[nJ][2],aTmpSepOs[nJ][3],aTmpSepOs[nJ][4],aTmpSepOs[nJ][5],aTmpSepOs[nJ][6]})
            Endif
        Next nJ

        // Verifica se há restrição por Produto
        SD2->(DbSetOrder(3)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
        SD2->(DbGoTop())
        For nJ := 1 To Len(aTmpGrp)
            If aTmpGrp[nJ][6] // Há restrição por Produto e não se trata de um agrupamento de requisições ou vale
                For nK := 1 To Len(aTmpGrp[nJ][1])
                    If Len(aTmpProd) > 0
                        cProdOri := ""
                        cProdDes := ""

                        // Produto título de origem
                        If SD2->(DbSeek(xFilial("SD2", aTmpGrp[nJ][1][nK][iif(lMVVFilOri,nPosFilOri,nPosFilial)])+aTmpGrp[nJ][1][nK][nPosNumero]+aTmpGrp[nJ][1][nK][nPosPrefixo]+aTmpGrp[nJ][1][nK][nPosCliente]+aTmpGrp[nJ][1][nK][nPosLoja])) //Exclusivo
                            cProdOri := SD2->D2_COD
                        Endif

                        For nL := 1 To Len(aTmpProd)
                            For nM := 1 To Len(aTmpProd[nL][1])
                                lAchou :=  .F.
                                cProdDes := ""

                                // Produto título de destino
                                If SD2->(DbSeek(xFilial("SD2", aTmpProd[nL][1][nM][iif(lMVVFilOri,nPosFilOri,nPosFilial)])+aTmpProd[nL][1][nM][nPosNumero]+aTmpProd[nL][1][nM][nPosPrefixo]+aTmpProd[nL][1][nM][nPosCliente]+aTmpProd[nL][1][nM][nPosLoja])) //Exclusivo
                                    cProdDest := SD2->D2_COD
                                Endif

                                If cProdOri == cProdDest ;
                                        .And. aTmpProd[nL][2] == aTmpGrp[nJ][2] ; //lSepFpg
                                    .And. aTmpProd[nL][3] == aTmpGrp[nJ][3] ; //lSepMot
                                    .And. aTmpProd[nL][4] == aTmpGrp[nJ][4] ; //lSepOrd
                                    .And. aTmpProd[nL][5] == aTmpGrp[nJ][5] ; //lRestGrp
                                    .And. aTmpProd[nL][6] == aTmpGrp[nJ][6]   //lRestPrd

                                    lAchou := .T.
                                    AAdd(aTmpProd[nL][1],aTmpGrp[nJ][1][nK])
                                    Exit
                                Endif
                            Next nM

                            If lAchou
                                Exit
                            Endif
                        Next nL

                        If !lAchou
                            AAdd(aTmpProd,{{aTmpGrp[nJ][1][nK]},aTmpGrp[nJ][2],aTmpGrp[nJ][3],aTmpGrp[nJ][4],aTmpGrp[nJ][5],aTmpGrp[nJ][6]})
                        Endif
                    Else
                        AAdd(aTmpProd,{{aTmpGrp[nJ][1][nK]},aTmpGrp[nJ][2],aTmpGrp[nJ][3],aTmpGrp[nJ][4],aTmpGrp[nJ][5],aTmpGrp[nJ][6]})
                    Endif
                Next nK
            Else
                AAdd(aTmpProd,{aTmpGrp[nJ][1],aTmpGrp[nJ][2],aTmpGrp[nJ][3],aTmpGrp[nJ][4],aTmpGrp[nJ][5],aTmpGrp[nJ][6]})
            Endif
        Next nJ

        //Adiciono item de fatura a ser gerada no acols
        For nL := 1 To Len(aTmpProd)

            aLinTmp := U_MontaDados("SE1", aT47Campos, .T.,,,.T.)
            dDtVenc := CToD("")
            nSldTit := 0
            nVlrTit := 0

            //{"MARK","E1_FILIAL","E1_FILORIG","E1_ORIGEM","E1_CLIENTE","E1_LOJA","A1_NOME","E1_XCGCEMI","A1_XCLASSE","E1_VENCTO","E1_VALOR","E1_VLRREAL","U57_MOTIVO"}
            aLinTmp[1] := "LBNO" //mark
            aLinTmp[aScan(aT47Campos,"E1_FILIAL")] := xFilial("SE1")
            aLinTmp[aScan(aT47Campos,"E1_FILORIG")] := cFilAnt
            aLinTmp[aScan(aT47Campos,"E1_CLIENTE")] := aTmpProd[nL][1][1][nPosCliente]
            aLinTmp[aScan(aT47Campos,"E1_LOJA")] := aTmpProd[nL][1][1][nPosLoja]
            aLinTmp[aScan(aT47Campos,"A1_NOME")] := aTmpProd[nL][1][1][nPosNome]
            aLinTmp[aScan(aT47Campos,"E1_XCGCEMI")] := aTmpProd[nL][1][1][nPosCGC]
            aLinTmp[aScan(aT47Campos,"A1_XCLASSE")] := aTmpProd[nL][1][1][nPosClasse]
            if nPosObsFat <> Nil .AND. nPosObsFat > 0 
                aLinTmp[aScan(aT47Campos,"E1_NOMCLI")] := aTmpProd[nL][1][1][nPosObsFat]
            endif

            For nM := 1 To Len(aTmpProd[nL][1])
                if aTmpProd[nL][1][nM][1]
                    aLinTmp[1] := "LBOK"
                endif

                //origem
                if !(Alltrim(aTmpProd[nL][1][nM][nPosTipo]) $ aLinTmp[aScan(aT47Campos,"E1_ORIGEM")])
                    if !empty(aLinTmp[aScan(aT47Campos,"E1_ORIGEM")])
                        aLinTmp[aScan(aT47Campos,"E1_ORIGEM")] += "/"
                    else
                        aLinTmp[aScan(aT47Campos,"E1_ORIGEM")] := "" //tiro espaços
                    endif
                    aLinTmp[aScan(aT47Campos,"E1_ORIGEM")] += Alltrim(aTmpProd[nL][1][nM][nPosTipo])
                endif

                //Motivo Saque
                if !(Alltrim(aTmpProd[nL][1][nM][nPosMotiv]) $ aLinTmp[aScan(aT47Campos,"U57_MOTIVO")])
                    if !empty(aLinTmp[aScan(aT47Campos,"U57_MOTIVO")])
                        aLinTmp[aScan(aT47Campos,"U57_MOTIVO")] += "/"
                    else
                        aLinTmp[aScan(aT47Campos,"U57_MOTIVO")] := ""
                    endif
                    aLinTmp[aScan(aT47Campos,"U57_MOTIVO")] += Alltrim(aTmpProd[nL][1][nM][nPosMotiv])
                endif

                //VENCIMENTO DA FATURA A SER GERADA
                //pego a maior data de vencimento
                If Empty(dDtVenc)
                    dDtVenc := CToD(aTmpProd[nL][1][nM][nPosVencto]) //Dt. vencimento
                Else
                    If dDtVenc < CToD(aTmpProd[nL][1][nM][nPosVencto])
                        dDtVenc := CToD(aTmpProd[nL][1][nM][nPosVencto])
                    Endif
                Endif
                //Se a data de vencimento for inferior a data atual
                If dDtVenc <= dDataBase
                    dDtVenc := dDataBase + nDiasVenc
                Endif
                //Se o intervalo entre a data de vencimento e a data atual for inferior a quantidade de dias necessários
                If dDtVenc - dDataBase < nDiasVenc
                    dDtVenc := dDtVenc + (nDiasVenc - (dDtVenc - dDataBase))
                Endif
                dDtVenc := DataValida(dDtVenc) //Compatibilidade com a data de vencimento do Boleto Bancário

                //VALOR LIQUIDO A SER GERADO
                If ValType(aTmpProd[nL][1][nM][nPosSaldo]) == "C" //Saldo
				    nSldTit += Val(StrTran(StrTran(cValToChar(aTmpProd[nL][1][nM][nPosSaldo]),".",""),",","."))
                Else
                    nSldTit += aTmpProd[nL][1][nM][nPosSaldo]
                Endif
                If ValType(aTmpProd[nL][1][nM][nPosAcresc]) == "C" //acrescimos
                    nSldTit += Val(StrTran(StrTran(cValToChar(aTmpProd[nL][1][nM][nPosAcresc]),".",""),",","."))
                Else
                    nSldTit += aTmpProd[nL][1][nM][nPosAcresc]
                Endif
                If ValType(aTmpProd[nL][1][nM][nPosDecres]) == "C" //decrescimos
                    nSldTit -= Val(StrTran(StrTran(cValToChar(aTmpProd[nL][1][nM][nPosDecres]),".",""),",","."))
                Else
                    nSldTit -= aTmpProd[nL][1][nM][nPosDecres]
                Endif
                If ValType(aTmpProd[nL][1][nM][nPosVlAcess]) == "C" //Valores acessórios
                    nSldTit += Val(StrTran(StrTran(cValToChar(aTmpProd[nL][1][nM][nPosVlAcess]),".",""),",","."))
                Else
                    nSldTit += aTmpProd[nL][1][nM][nPosVlAcess]
                Endif

                //VALOR BRUTO A SER GERADO
                If ValType(aTmpProd[nL][1][nM][nPosValor]) == "C" //Valores acessórios
                    nVlrTit += Val(StrTran(StrTran(cValToChar(aTmpProd[nL][1][nM][nPosValor]),".",""),",","."))
                Else
                    nVlrTit += aTmpProd[nL][1][nM][nPosValor]
                Endif

                //add recno dos titulos origem
                aadd(aLinTmp[nPosInfoAd], aTmpProd[nL][1][nM][nPosRecno])

            Next nM  

            aLinTmp[aScan(aT47Campos,"E1_VENCTO")] := dDtVenc
            aLinTmp[aScan(aT47Campos,"E1_VALOR")] := nSldTit
            aLinTmp[aScan(aT47Campos,"E1_VLRREAL")] := nVlrTit

            aadd(oGridDet:aCols, aLinTmp)

        next nL

    next nI

    if empty(oGridDet:aCols)
        aadd(oGridDet:aCols, U_MontaDados("SE1", aT47Campos, .T.,,,.T.))
    endif

    oGridDet:oBrowse:Refresh()

Return

/*/{Protheus.doc} ObsCliente
Funcao para exibir as observacoes do cliente
@type function
@version 1.0
@author g.sampaio
@since 02/10/2023
@param cCodCliente, character, Codigo do Cliente
@param cCodLoja, character, Codigo Loja
/*/
Static Function ObsCliente(cCodCliente, cCodLoja)

	Local aArea			:= GetArea()
	Local aAreaSA1		:= SA1->(GetArea())
	Local cObservacoes	:= ""
	Local oDlgObs		:= Nil

	Default cCodCliente	:= ""
	Default cCodLoja	:= ""

	SA1->(DbSelectArea(1))
	If SA1->(MsSeek(xFilial("SA1")+cCodCliente+cCodLoja))

		// observacoes do cliente
		cObservacoes := SA1->A1_XOBSFAT

		If !Empty(cObservacoes)

			//Define Font oFont Name "Mono AS" Size 5, 12
			Define MsDialog oDlgObs Title "Observações do Cliente:" From 3, 0 to 340, 417 Pixel

			@ 5, 5 Get oMemo Var cObservacoes When .F. Memo Size 200, 145 Of oDlgObs Pixel
			oMemo:bRClicked := { || AllwaysTrue() }			

			Define SButton From 153, 175 Type 1 Action oDlgObs:End() Enable Of oDlgObs Pixel // OK			

			Activate MsDialog oDlgObs Center

		Else
			MsgAlert("Não existem observações de faturamento para o cliente!.","Atenção")

		EndIf

	EndIf

	RestArea(aAreaSA1)
	RestArea(aArea)

Return(Nil)
