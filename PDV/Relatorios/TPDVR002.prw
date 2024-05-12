#INCLUDE "RWMAKE.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} TPDVR002
Imprimir comprovante de saque

@author Totvs TBC
@since 30/07/2014
@version 1.0

@return ${return}, ${return_description}

@param nVale, numeric, valor do troco em vale haver
@param nDinheiro, numeric, valor do troco em dinheiro
@param nCheque, numeric, valor do troco em cheque troco
@param cTitulo, characters, numero do título
@param cRequis, characters, codigo da requisicao
@param cCargo, characters, descricao do cargo
@param cMotivo, characters, motivo do saque
@param cTipoReq, characters, tipo de requisicao

@type function
/*/
User Function TPDVR002(cCodCli, cLojCli, cPlaca, cCgcMot, cNomMot, nVale, nDinheiro, nCheque, cTitulo, cRequis, cCargo, cMotivo, cTipoReq)

Local aAreaSM0 := SM0->( GetArea() )
Local nX
Local nLarg         := 48 //considera o cupom de 48 posições
Local _nRet
Local _cNumPdv		:= Space(6) //Numero do PDV 
Local _cNumCup		:= Space(6) //Numero do cupom
Local _aMsg			:= {} //mensagens do cupom
Local _cMsg         := ""
Local _cRetorno		:= Space(10) //retorno
Local nVias         := 2 //numero de vias (2 - uma para o cliente outra para a marajo)
Default cMotivo		:= ""

If nVale > 0 //.and. MsgYesNo("Deseja imprimir o cupom não fiscal?","Atenção - Saque")

	//forço o posicionamento na SM0
	SM0->(DbGoTop())
	While SM0->(!Eof())
		If (AllTrim(SM0->M0_CODFIL) == AllTrim(cFilAnt)) .and. (AllTrim(SM0->M0_CODIGO) == AllTrim(cEmpAnt))
			Exit
		EndIf
	 	SM0->(DbSkip())
	EndDo

	_aMsg := {} //mensagens do cupom
	//mensagem
	AAdd( _aMsg, Space(nLarg) )
	AAdd( _aMsg, Replicate("-",nLarg) )
	AAdd( _aMsg, PadC(AllTrim(SM0->M0_NOMECOM), nLarg) )
	AAdd( _aMsg, PadC("("+AllTrim(SM0->M0_FILIAL)+")", nLarg) )
	AAdd( _aMsg, PadC("CNPJ: " +Substr(SM0->M0_CGC,1,2)+ "." +Substr(SM0->M0_CGC,3,3)+ "." +Substr(SM0->M0_CGC,6,3)+ "/" +Substr(SM0->M0_CGC,9,4)+ "-" +Substr(SM0->M0_CGC,13,2), nLarg) )
	AAdd( _aMsg, Replicate("-",nLarg) )
	AAdd( _aMsg, Space(nLarg) )
	AAdd( _aMsg, "COMPROVANTE DE SAQUE")
	AAdd( _aMsg, cTipoReq)
	AAdd( _aMsg, "N.: "+cTitulo)
	AAdd( _aMsg, Space(nLarg) )
	AAdd( _aMsg, "DATA.......: "+DtoC(date())+"        HORA...: "+time())
	AAdd( _aMsg, Space(nLarg) )
	AAdd( _aMsg, "OPERADOR...: "+AllTrim(SA6->A6_COD)+" - "+AllTrim(SA6->A6_NOME))
	AAdd( _aMsg, "CLIENTE....: "+cCodCli+"/"+cLojCli+"-"+SubStr(AllTrim(Posicione("SA1",1,xFilial("SA1")+cCodCli+cLojCli,"A1_NOME")),1,26))
	AAdd( _aMsg, "AUTORIZANTE: "+SubStr(AllTrim(cRequis),1,35))
	If !Empty(cCargo) // caso esteja preenchido faco a impressao
		AAdd( _aMsg, "CARGO......: "+SubStr(AllTrim(cCargo),1,35))
	EndIf
	AAdd( _aMsg, "PLACA......: "+AllTrim(cPlaca))
	If !Empty(cNomMot)
		AAdd( _aMsg, "MOTORISTA..: "+AllTrim(cCgcMot)+" - "+SubStr(AllTrim(cNomMot),1,21))
	Else
		AAdd( _aMsg, "MOTORISTA..: "+AllTrim(cCgcMot)+" - "+SubStr(AllTrim(Posicione("DA4",3,xFilial("DA4")+cCgcMot,"DA4_NOME")),1,21))
	EndIf
	AAdd( _aMsg, Space(nLarg) )
	If !Empty(cMotivo)
		cDesMot := Posicione("SX5",1,XFilial("SX5")+"UX"+cMotivo,"X5_DESCRI")
		AAdd( _aMsg, "MOTIVO.....: "+AllTrim(cDesMot))
		AAdd( _aMsg, Space(nLarg) )
	EndIf
	AAdd( _aMsg, Replicate("-",nLarg) )
	AAdd( _aMsg, "VALOR VALE.: R$ "+AllTrim(Transform(nVale,"@E 999,999,999.99")))
	cExtenso := "**("+AllTrim(Extenso(nVale))+")**"
	While !empty(cExtenso)
		 AAdd( _aMsg, substr(cExtenso,1,nLarg) )
		 if len(cExtenso) > nLarg
		 	cExtenso := substr(cExtenso,nLarg+1)
		 else
		 	cExtenso := ""
		 endif
	EndDo
	AAdd( _aMsg, Space(nLarg) )
	AAdd( _aMsg, Replicate('-',Int((nLarg-10)/2))+"COMPOSIÇÃO"+Replicate('-',Int((nLarg-10)/2)))
	AAdd( _aMsg, "DINHEIRO...: R$ "+AllTrim(Transform(nDinheiro,"@E 999,999,999.99")))
	AAdd( _aMsg, "CHEQUE TROC: R$ "+AllTrim(Transform(nCheque,"@E 999,999,999.99")))
	AAdd( _aMsg, Space(nLarg) )
	AAdd( _aMsg, Replicate("-",nLarg) )  
	AAdd( _aMsg, Space(nLarg) )
	cExtenso := "Declaro ter recebido da empresa "+AllTrim(SM0->M0_NOMECOM)+" a importancia acima, a titulo de vale."
	While !empty(cExtenso)
		 AAdd( _aMsg, substr(cExtenso,1,nLarg) )
		 if len(cExtenso) > nLarg
		 	cExtenso := substr(cExtenso,nLarg+1)
		 else
		 	cExtenso := ""
		 endif
	EndDo
	AAdd( _aMsg, Space(nLarg) )
	cExtenso := "Por ser verdade assino o presente."
	While !empty(cExtenso)
		 AAdd( _aMsg, substr(cExtenso,1,nLarg) )
		 if len(cExtenso) > nLarg
		 	cExtenso := substr(cExtenso,nLarg+1)
		 else
		 	cExtenso := ""
		 endif
	EndDo
	AAdd( _aMsg, Space(nLarg) ) 
	AAdd( _aMsg, Space(nLarg) )
	AAdd( _aMsg, Replicate("_",nLarg))
	AAdd( _aMsg, "MOTORISTA..: "+AllTrim(cCgcMot)+" - "+SubStr(AllTrim(cNomMot),1,21))
	
	For nX:=1 to Len( _aMsg )
		_cMsg += _aMsg[nX] + chr(10)
	Next nX
	//fim da montagem da mensagem
	
	//função para impressão do comprovante
	For nX:=1 to nVias
		//parametro nVias=1 para fazer o corte
		STWManagReportPrint( _cMsg , 1/*nVias*/ )
	Next nX

EndIf

RestArea( aAreaSM0 )

Return _nRet
