#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TPDVR001
Rotina de Impressao do Relatorio Gerencial (Convênio - Venda a Prazo)
Tipo: Rotina de Impressão
Uso: Ponto de entrada: STFinishSale

@author thebr
@since 21/12/2018
@version 1.0
@return Nil

@type function
/*/

/* LAYOUT FORNECIDO -> 48 POSIÇÕES
1         2         3         4       4
123456789012345678901234567890123456789012345678

MARAJO APARECIDA DE GOIANIA
CNPJ: 05443159000102
------------------------------------------------
COMPROVANTE DE VENDA A PRAZO
------------------------------------------------

Cliente: XXXXXX - VAZ E CRUZ LTDA
Caixa: ROSA VAZ
CPF/CNPJ: 999999999999
RG/IE: 99999999999
End:
N. Cupom:
Placa:
Veículo:
Odometro:
Motorista:

Frota: LITROS 46,76
($) Soma                                 134,08
NOTA A PRAZO                             134,08
------------------------------------------------


Ass.:
------------------------------------------------
*/

User function TPDVR001()

	Local aArea    := GetArea()
	Local aAreaSL1 := SL1->( GetArea() )
	Local aAreaSL2 := SL2->( GetArea() )
	Local aAreaSL4 := SL4->( GetArea() )
	Local aAreaSA1 := SA1->( GetArea() )
	Local aAreaSM0 := SM0->( GetArea() )

	Local nLarg         := 48
	Local aMsgImp		:= {} //mensagens do cupom
	Local cMsgImp       := ""
	Local nTotal		:= 0 //valor total da venda
	Local cTotal		:= ""
	Local cLitros      := ""
	Local nTotalCC		:= 0 //valor total da conta consumo
	Local cOrcamento	:= SL1->L1_NUM  //numero do orcamento
	Local cFPConv 		:= SuperGetMv("TP_FPGCONV",,"")
	Local aFormas		:= StrTokArr("NP|CT|"+cFPConv,"|") //as formas que geram Relatorio Gerencial
	Local aPgtos       := {}
	Local nVias         := SuperGetMv("MV_XVIASNP",,2) //numero de vias do comprovante
	Local cClasse		:= ""
	Local nTotLit		:= 0
	Local nI := 0, nX := 0
	Local nLjTrDin		:= SuperGetMV("MV_LJTRDIN",,0)

	//posiciona nos arquivos utilizados
	SL4->(DbSetOrder(1)) //L4_FILIAL+L4_NUM+L4_ORIGEM
	SL4->(DbSeek(xFilial("SL4") + cOrcamento))

	SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
	SA1->(DbSeek(xFilial("SA1") + SL1->L1_CLIENTE + SL1->L1_LOJA))

	//forço o posicionamento na SM0
	SM0->(DbGoTop())
	While SM0->(!Eof())
		If (AllTrim(SM0->M0_CODFIL) == AllTrim(cFilAnt)) .and. (AllTrim(SM0->M0_CODIGO) == AllTrim(cEmpAnt))
			Exit //sai do While SM0
		EndIf
		SM0->(DbSkip())
	EndDo

	//verifica se possui a forma de pagamento para impressao do cupom nao fiscal
	SL4->(DbGoTop())
	If SL4->(DbSeek(xFilial("SL4") + cOrcamento))

		_nTotFor  := 0
		cL4_FORMA := SL4->L4_FORMA

		//{"DESCRICAO","VALOR","FORMA"}
		AAdd(aPgtos, {AllTrim(RetField("SX5",1,xFilial("SX5")+"24"+SL4->L4_FORMA,"X5_DESCRI")), "", SL4->L4_FORMA})

		While !SL4->( EOF() ) .and. SL4->L4_FILIAL == xFilial("SL4") .and. SL4->L4_NUM == cOrcamento

			If cL4_FORMA <> SL4->L4_FORMA

				nPosFor := aScan( aPgtos, { |x| AllTrim(x[3]) == AllTrim(cL4_FORMA)} )
				If nPosFor > 0
					aPgtos[nPosFor][2] := Alltrim(Transform(_nTotFor,"@E 999,999,999.99"))
				Else
					AAdd(aPgtos, {AllTrim(RetField("SX5",1,xFilial("SX5")+"24"+SL4->L4_FORMA,"X5_DESCRI")), "", SL4->L4_FORMA})
				EndIf

				_nTotFor  := 0
				cL4_FORMA := SL4->L4_FORMA

			EndIf

			If aScan( aFormas, { |x| AllTrim(x) == AllTrim(SL4->L4_FORMA)} ) <> 0 ;
				.and. AllTrim(SL4->L4_FORMA) <> "PX" //ajuste para não imprimir comprovante para a forma PIX
				//total da conta consumo
				nTotalCC += SL4->L4_VALOR - SL4->L4_TROCO //total da forma especifica
			EndIf

			//incrementa a variavel de valor total
			//MV_LJTRDIN -> Define se grava o valor liquido do troco em dinheiro. (0-Nao Utiliza ; 1-Gera Valor Liquido)
			If AllTrim(SL4->L4_FORMA) == 'R$' .and. nLjTrDin <> 0 //se parametro ativo a forma de R$ é com valor liquido
				_nTotFor += SL4->L4_VALOR + SL4->L4_TROCO //total da forma especifica
				nTotal += SL4->L4_VALOR + SL4->L4_TROCO //total da forma especifica
			Else
				_nTotFor += SL4->L4_VALOR - SL4->L4_TROCO //total da forma especifica
				nTotal += SL4->L4_VALOR - SL4->L4_TROCO //total da forma especifica
			EndIf

			SL4->( DbSkip() )
		EndDo

		nPosFor := aScan( aPgtos, { |x| AllTrim(x[3]) == AllTrim(cL4_FORMA)} )
		If nPosFor > 0
			aPgtos[nPosFor][2] := Alltrim(Transform(_nTotFor,"@E 999,999,999.99"))
		Else
			//AAdd(aPgtos,{"DESCRICAO","VALOR","FORMA"}
			AAdd(aPgtos, {AllTrim(RetField("SX5",1,xFilial("SX5")+"24"+cL4_FORMA,"X5_DESCRI")), Alltrim(Transform(_nTotFor,"@E 999,999,999.99")), cL4_FORMA})
		EndIf

		cTotal := Alltrim(Transform(nTotal,"@E 999,999,999.99"))

	EndIf

	//possui a forma de pagamento para impressao do cupom nao fiscal
	If nTotalCC > 0 .and. ExistBlock("TPR001IM")
		//Ponto de Entrada TPR001IM - que permite a impressão customizada pelo usuário do comprovante de venda a prazo
		ExecBlock("TPR001IM",.F.,.F.) //

	ElseIf nTotalCC > 0 //.and. MsgYesNo("Deseja imprimir o cupom não fiscal referente ao comprovante de venda com Convênio?","Atenção - Convênio")

		AAdd( aMsgImp, Space(nLarg) )
		AAdd( aMsgImp, PadC(AllTrim(SM0->M0_NOMECOM), nLarg) )
		AAdd( aMsgImp, PadC("("+AllTrim(SM0->M0_FILIAL)+")", nLarg) )
		AAdd( aMsgImp, PadC("CNPJ: " +Substr(SM0->M0_CGC,1,2)+ "." +Substr(SM0->M0_CGC,3,3)+ "." +Substr(SM0->M0_CGC,6,3)+ "/" +Substr(SM0->M0_CGC,9,4)+ "-" +Substr(SM0->M0_CGC,13,2), nLarg) )
		AAdd( aMsgImp, PadR("EMISSÃO: " + dtoc( date() ) + "   HORA: " + time() ,nLarg) )
		AAdd( aMsgImp, Space(nLarg) )
		AAdd( aMsgImp, Replicate("-",nLarg) )
		AAdd( aMsgImp, Replicate(chr(32),10)+PadR("COMPROVANTE DE VENDA A PRAZO",nLarg-10 ) )
		AAdd( aMsgImp, Replicate("-",nLarg) )
		AAdd( aMsgImp, Space(nLarg) )

		AAdd( aMsgImp, PadR("Cliente: "+AllTrim(SA1->A1_COD)+"/"+AllTrim(SA1->A1_LOJA)+" - "+AllTrim(SA1->A1_NOME), nLarg) )
		If SA1->(FieldPos("A1_XCLASSE"))>0 .AND. !Empty(SA1->A1_XCLASSE)
			cClasse := AllTrim(POSICIONE("UF6",1,XFILIAL('UF6')+SA1->A1_XCLASSE,"UF6_DESC"))
			If !Empty(cClasse)
				AAdd( aMsgImp, PadR("Classe: "+cClasse, nLarg) )
			EndIf
		EndIf
		AAdd( aMsgImp, PadR("Caixa: "+AllTrim(SA6->A6_COD)+" - "+AllTrim(SA6->A6_NOME) + space(05) + "PDV: " + SLG->LG_PDV, nLarg) )
		If SA1->A1_PESSOA == "J"
			AAdd( aMsgImp, PadR("CNPJ: "+transform(SA1->A1_CGC,"@R 99.999.999/9999-99"), nLarg) )
			AAdd( aMsgImp, PadR("IE: "+AllTrim(SA1->A1_INSCR), nLarg) )
		Else//If SA1->A1_PESSOA == "F"
			AAdd( aMsgImp, PadR("CPF: "+transform(SA1->A1_CGC,"@R 999.999.999-99"), nLarg) )
			AAdd( aMsgImp, PadR("RG: "+AllTrim(SA1->A1_PFISICA), nLarg) )
		EndIf
		AAdd( aMsgImp, PadR("End: "+AllTrim(SA1->A1_END)+", "+AllTrim(SA1->A1_BAIRRO)+", "+AllTrim(SA1->A1_MUN)+", "+AllTrim(SA1->A1_EST), nLarg) )
		AAdd( aMsgImp, PadR("N. Documento / Serie: "+SL1->L1_DOC + " / " + SL1->L1_SERIE , nLarg) )

		AAdd( aMsgImp, PadR("Placa: " + AllTrim(Transform(SL1->L1_PLACA,"@!R NNN-9N99" )), nLarg) )
		AAdd( aMsgImp, PadR("Odometro: " + Alltrim(Transform((SL1->L1_ODOMETR),"@E 99999999999")), nLarg) )
		If SL1->(FieldPos("L1_NOMMOTO"))>0 .AND. !empty(SL1->L1_NOMMOTO)
			AAdd( aMsgImp, PadR("Motorista: " + AllTrim(SL1->L1_NOMMOTO), nLarg) )
		EndIf
		AAdd( aMsgImp, Space(nLarg) )

		SL2->(DbSetOrder(1)) //L2_FILIAL+L2_NUM+L2_ITEM+L2_PRODUTO
		If SL2->(DbSeek(xFilial("SL2")+cOrcamento))
			nTotLit := 0
			While SL2->(!EOF()) .and. SL2->L2_FILIAL == xFilial("SL2") .and. SL2->L2_NUM == cOrcamento
				If SL2->L2_UM = 'L '
					nTotLit += SL2->L2_QUANT
				EndIf
				SL2->(DbSkip())
			EndDo
			cLitros := Alltrim(Transform(nTotLit,"@E 999,999,999.99"))
		EndIf

		AAdd( aMsgImp, PadR("Frota: "+Space(34-len(cLitros))+cLitros+" LITROS", nLarg) )
		AAdd( aMsgImp, Replicate("-", nLarg) )
		AAdd( aMsgImp, PadR("($) Soma"+Space(40-len(cTotal))+cTotal, nLarg) )
		For nI:=1 to Len(aPgtos)
			AAdd( aMsgImp, PadR(aPgtos[nI][1]+Space(nLarg-(len(aPgtos[nI][1]+aPgtos[nI][2])))+aPgtos[nI][2], nLarg) )
		Next nI
		AAdd( aMsgImp, Replicate("-", nLarg) )
		AAdd( aMsgImp, Space(nLarg) )
		AAdd( aMsgImp, Space(nLarg) )
		AAdd( aMsgImp, Padc("Ass.:", nLarg) )
		AAdd( aMsgImp, Replicate("-", nLarg) )

		For nX:=1 to Len( aMsgImp )
			cMsgImp += aMsgImp[nX] + chr(10)
		Next nX

		//Funçao para impressao do comprovante
		For nX:=1 to nVias
			//parametro nVias=1 para fazer o corte
			STWManagReportPrint( cMsgImp , 1/*nVias*/ )
		next nX

	EndIf

	RestArea( aAreaSM0 )
	RestArea( aAreaSL1 )
	RestArea( aAreaSL2 )
	RestArea( aAreaSL4 )
	RestArea( aAreaSA1 )
	RestArea( aArea )

Return
