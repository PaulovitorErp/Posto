#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TOPCONN.CH'
#INCLUDE 'RWMAKE.CH'
#INCLUDE 'TBICONN.CH'

//------------------------------------------------------------
/*/{Protheus.doc} LJDEPSE1
Este Ponto de Entrada é acionado na finalização do venda Assistida após a gravação do título a receber na tabela SE1, 
possibilitando que sejam realizadas gravações complementares no titulo inserido.
O registro inserido fica posicionado para uso no Ponto de Entrada.

@param ParamIxb
Parâmetros: O Ponto de Entrada recebe o array das parcelas a receber definidas na venda (SL4).

Aadd(aReceb,{SL4->L4_DATA		    ,;	                                        //01 - Data de vencimento
		         SL4->L4_VALOR		,;	                                        //02 - Valor da parcela
		         SL4->L4_FORMA		,;	                                        //03 - Forma de recebimento
		         SL4->L4_ADMINIS	,;	                                        //04 - Codigo e nome da Administradora
		         SL4->L4_NUMCART	,;	                                        //05 - Numero do cartao/cheque
		         SL4->L4_AGENCIA	,;	                                        //06 - Agencia do cheque
		         SL4->L4_CONTA		,; 	                                        //07 - Numero da conta do cheque
		         SL4->L4_RG			,;	                                        //08 - RG do portador do cheque
		         SL4->L4_TELEFON	,; 	                                        //09 - Telefone do portador do cheque
		         SL4->L4_TERCEIR	,; 	                                        //10 - Indica se o cheque e de terceiros
		         Iif(cPaisLoc == "BRA",1,SL4->L4_MOEDA),; 						//11 - Moeda da parcela
		         cParcTEF,;          											//12 - Tipo de parcelamento(Client SiTEF DLL)
			   	 Iif(cPaisLoc == "BRA", SL4->L4_ACRSFIN, 0),;					//13 - Acrescimo Financeiro
			   	 SL4->L4_NOMECLI	,;											//14 - Nome Emitente quando cheque de terceiro
			   	 SL4->L4_FORMAID	,; 											//15 - ID do Cartao de Credito ou Debito
			   	 cNSUTEF			,;											//16 - NSU da trasacao TEF
			   	 cDocTEF  			,; 											//17 - Num. Documento TEF
			   	 SL4->(Recno())		,;  										//18 - Numero Registro SL4
			   	 Iif(SL4->(ColumnPos("L4_DESCMN")) > 0 , SL4->L4_DESCMN , 0 ),;	//19 - Desconto MultNegociacao
			   	 Iif(lIntegHtl, SL4->L4_CONHTL, "") ,; 							//20 - Conta Hotel
				 cAUTTEF 			,; 											//21 - Codigo Autorizacao TEF
				 SL4->L4_COMP  		,; 											//22 - Compesacao
				 cIdCNAB  			}) 											//23 - IDCNAB

@return Nenhum(nulo)
@author Pablo Cavalcante
@since 22/11/2019 - data de revisão do artefato

/*/
//------------------------------------------------------------

User Function TRETP028()

Local aParcelas := aClone(PARAMIXB[1])
Local cPortador := ""
Local cFPConv := SuperGetMv("TP_FPGCONV",,"")
Local lHasSEF := .F.
Local aArea	   	:= GetArea()
Local aAreaSL1 	:= SL1->(GetArea())
Local aAreaSL2 	:= SL2->(GetArea())
Local aAreaSL4 	:= SL4->(GetArea())
Local aAreaSE1 	:= SE1->(GetArea())

Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
//Caso o Posto Inteligente não esteja habilitado não faz nada...
If !lMvPosto
	Return
EndIf

//-- Garantir liberaçao de locks
DbCommitAll()
MsUnLockAll()

Private bFiltraBrw := {||} //usado por compatibilidade por causa do fonte SPEDNFE.PRX

//Conout("")
//Conout("")
//Conout(" >> ------------------------------------------------------------ << ")
//Conout("PE LJDEPSE1 - PE acionado após a gravação do título a receber na tabela SE1")
//Conout("PE LJDEPSE1 - Data/hora INICIO de Execucao - Data: "+DTOS(DDataBase)+" - Hora: "+cValToChar(Time())+"")
//conout("	>> ParamIxb: "+U_XtoStrin(ParamIxb))

If SE1->(Eof())
    //Conout("PE LJDEPSE1 - SE1 não posicionado...")
    //Conout(" >> ------------------------------------------------------------ << ")
    Return
EndIf

If ValType(aParcelas) == "A" .and. Len(aParcelas) >= 18 .AND. aParcelas[18] <> 0
    dbSelectArea("SL4")
    SL4->(DbSetOrder(1))
    SL4->(DbGoTo(aParcelas[18]))
Else
    //Conout("PE LJDEPSE1 - SL4 não posicionado...")
    //Conout(" >> ------------------------------------------------------------ << ")
    Return
EndIf

//Amarracao Formas de Pagamento x Clientes
If ChkFile("U88")
    U88->(DbSetOrder(1)) //U88_FILIAL+U88_FORMAP+U88_CLIENT+U88_LOJA
    If U88->(dbSeek(xFilial("U88")+Padr(SE1->E1_TIPO,TamSX3("U88_FORMAP")[1])+SE1->E1_CLIENTE+SE1->E1_LOJA))
        cPortador  := U88->U88_BANCOC
    EndIf
EndIf

If Empty(cPortador)
    cPortador := Posicione("SA1",1,SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_BCO1")
EndIf

//Ajusta campos customizados do título
RecLock("SE1",.F.)

    If SE1->(FieldPos("E1_XPLACA")) > 0
        SE1->E1_XPLACA	:= SL1->L1_PLACA
    EndIf

    If SE1->(FieldPos("E1_XPDV")) > 0
        SE1->E1_XPDV	:= SL1->L1_PDV
    EndIf

    If SL4->(FieldPos("L4_XCOND")) > 0 .AND. SE1->(FieldPos("E1_XCOND")) > 0 .AND. SE1->(FieldPos("E1_XDTFATU")) > 0
        SE1->E1_XCOND	:= SL4->L4_XCOND
        SE1->E1_XDTFATU := U_TRETE014(SE1->E1_XCOND,SE1->E1_VENCTO)
    EndIf

    If Alltrim(SE1->E1_TIPO) == "CH"
        If SE1->(FieldPos("E1_XCODEMI")) > 0
            SE1->E1_XCODEMI := Posicione("SA1",3,xFilial("SA1")+SL4->L4_CGC,"A1_COD")
            SE1->E1_XLOJEMI := SA1->A1_LOJA
            SE1->E1_XCGCEMI := SL4->L4_CGC
        EndIf

        cBanco := PADR(alltrim(SL4->L4_ADMINIS),TamSx3("EF_BANCO")[1])
        cAgenc := PADR(alltrim(SL4->L4_AGENCIA),TamSx3("EF_AGENCIA")[1])
        cConta := PADR(alltrim(SL4->L4_CONTA)  ,TamSx3("EF_CONTA")[1])
        cNumCh := PADR(alltrim(SL4->L4_NUMCART),TamSx3("EF_NUM")[1])
        // Posiciona o cheque dentro do SEF
        DbSelectArea("SEF")
        SEF->(DbSetOrder(1)) //1 - EF_FILIAL+EF_BANCO+EF_AGENCIA+EF_CONTA+EF_NUM
        If SEF->(DbSeek(xFilial("SEF")+ cBanco + cAgenc + cConta + cNumCh))
            lHasSEF := .T.
            RecLock("SEF",.F.)
                SEF->EF_COMP 	:= SL4->L4_COMP //Compens.
                SEF->EF_EMITENT := SL4->L4_NOMECLI //nome emitente
                SEF->EF_CPFCNPJ := SL4->L4_CGC //CPF ou CNPJ
                If SEF->(FieldPos("EF_XCODEMI")) > 0
                    SEF->EF_XCODEMI := Posicione("SA1",3,xFilial("SA1")+SL4->L4_CGC,"A1_COD")
                    SEF->EF_XLOJEMI := SA1->A1_LOJA
                EndIf
                If SEF->(FieldPos("EF_XCMC7")) > 0
                    SEF->EF_XCMC7 	:= SL4->L4_OBS //CMC7
                EndIf
                If SEF->(FieldPos("EF_XPDV")) > 0
                    SEF->EF_XPDV	:= SL1->L1_PDV
                EndIf
                if empty(SEF->EF_FILORIG)
                    SEF->EF_FILORIG 	:= cFilAnt
                endif
            SEF->( msUnlock() )
        EndIf
    EndIf

    If Alltrim(SE1->E1_TIPO) == "NP" .AND. SuperGetMV("TP_ACTNP",,.F.)
        SE1->E1_NATUREZ	:= SuperGetMv("TP_NATNP",.F.,"")
    EndIf

    If Alltrim(SE1->E1_TIPO) == "CT" .AND. SuperGetMV("TP_ACTCT",,.F.)
        SE1->E1_NATUREZ	:= SuperGetMv("TP_NATCT",.F.,"")
    EndIf

    If Alltrim(SE1->E1_TIPO) $ cFPConv .AND. !empty(SuperGetMV("TP_NAT"+Alltrim(SE1->E1_TIPO),,""))
        SE1->E1_NATUREZ	:= SuperGetMV("TP_NAT"+Alltrim(SE1->E1_TIPO),,"")
    endif

    If Alltrim(SE1->E1_TIPO) == "CF" .AND. SuperGetMV("TP_ACTCF",,.F.)
        SE1->E1_NATUREZ	:= SuperGetMv("TP_NATCF",.F.,"")
        SE1->E1_NUMCART := SL4->L4_NUMCART
        SE1->E1_HIST 	:= SL4->L4_OBS
        SE1->E1_CLIENTE := Posicione("SA1",3,xFilial("SA1")+SL4->L4_CGC,"A1_COD")
        SE1->E1_LOJA	:= SA1->A1_LOJA
        SE1->E1_NOMCLI	:= SA1->A1_NOME
    EndIf

    If !Empty(cPortador)
        SE1->E1_PORTADO := cPortador
    EndIf

SE1->(MsUnlock())

//ponto de entrada para manipular campos da SEF ou SE1 referente a cheques
//Já posicionado em ambas tabelas SE1 e SEF
If lHasSEF .AND. ExistBlock("TPINCSEF")
    ExecBlock("TPINCSEF",.F.,.F.,{"1"}) //Parametros; 1=Venda (gravabatch); 2=Compensação; 3=Conferencia Caixa
EndIf

//Conout("")
//Conout("PE LJDEPSE1 - Orçamento: " + SL1->L1_NUM + " - Doc/Serie: " + SL1->L1_DOC + "/" + SL1->L1_SERIE + "")
//Conout("PE LJDEPSE1 - Data/hora FIM de Execucao - Data: "+DTOS(DDataBase)+" - Hora: "+cValToChar(Time())+"")
//Conout(" >> ------------------------------------------------------------ << ")
//Conout("")
//Conout("")

//-- Garantir liberaçao de locks
DbCommitAll()
MsUnlockAll()

RestArea(aAreaSL1)
RestArea(aAreaSL2)
RestArea(aAreaSL4)
RestArea(aAreaSE1)

Restarea(aArea)

Return
