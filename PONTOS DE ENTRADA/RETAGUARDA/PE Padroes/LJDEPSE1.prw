#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TOPCONN.CH'
#INCLUDE 'RWMAKE.CH'
#INCLUDE 'TBICONN.CH'

//------------------------------------------------------------
/*/{Protheus.doc} LJDEPSE1
Este Ponto de Entrada é acionado na finalização do Venda Assistida após a gravação do título a receber na tabela SE1, 
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
		         IIf(cPaisLoc == "BRA",1,SL4->L4_MOEDA),; 						//11 - Moeda da parcela
		         cParcTEF,;          											//12 - Tipo de parcelamento(Client SiTEF DLL)
			   	 IIf(cPaisLoc == "BRA", SL4->L4_ACRSFIN, 0),;					//13 - Acrescimo Financeiro
			   	 SL4->L4_NOMECLI	,;											//14 - Nome Emitente quando cheque de terceiro
			   	 SL4->L4_FORMAID	,; 											//15 - ID do Cartao de Credito ou Debito
			   	 cNSUTEF			,;											//16 - NSU da trasacao TEF
			   	 cDocTEF  			,; 											//17 - Num. Documento TEF
			   	 SL4->(Recno())		,;  										//18 - Numero Registro SL4
			   	 IIf(SL4->(ColumnPos("L4_DESCMN")) > 0 , SL4->L4_DESCMN , 0 ),;	//19 - Desconto MultNegociacao
			   	 IIf(lIntegHtl, SL4->L4_CONHTL, "") ,; 							//20 - Conta Hotel
				 cAUTTEF 			,; 											//21 - Codigo Autorizacao TEF
				 SL4->L4_COMP  		,; 											//22 - Compesacao
				 cIdCNAB  			}) 											//23 - IDCNAB

@return Nenhum(nulo)
@author Pablo Cavalcante
@since 22/11/2019 - data de revisão do artefato

/*/
//------------------------------------------------------------

User Function LJDEPSE1()

Local aParam := aClone(ParamIxb)

///////////////////////////////////////////////////////////////////////////////////////////
//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
/////////////////////////////////////////////////////////////////////////////////////////
If ExistBlock("TRETP028")
	ExecBlock("TRETP028",.F.,.F.,aParam)
Endif
    
Return()
