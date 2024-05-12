#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TRETM008
Ponto de entrada que ira gravar os dados do abastecimento.

@author pablo
@since 16/10/2018
@version 1.0
@return Nil

@type function
/*/
User Function TRETM008()

	Local aArea			:= GetArea()
	Local aAreaMID		:= MID->(GetArea())
	Local aParam 		:= PARAMIXB
	Local oObj			:= aParam[1]
	Local cIdPonto		:= aParam[2]
	Local oModelMID		:= oObj:GetModel( 'MIDMASTER' )
	Local lRet			:= .T.
	Local dDataAbast	:= dDataBase
	Local cHoraAbast	:= ""
	Local cConcent		:= ""
	Local cLado			:= ""
	Local cNLogic		:= ""
	Local nQtdAbast		:= 0
	Local cMsg			:= ""

	If cIdPonto ==  'MODELPOS' // confirmação do cadastro

		if oObj:GetOperation() == 3 // inclusão

			dDataAbast 	:= oModelMID:GetValue( 'MID_DATACO' )
			cHoraAbast	:= oModelMID:GetValue( 'MID_HORACO' )
			nQtdAbast	:= oModelMID:GetValue( 'MID_LITABA' )
			cConcent	:= oModelMID:GetValue( 'MID_XCONCE' )
			cLado		:= oModelMID:GetValue( 'MID_LADBOM' )
			cNLogic		:= oModelMID:GetValue( 'MID_NLOGIC' )

			// Verifico se existe um abastecimento com este número lógico cadastrado com mesma data/hora/quantidade
			// É necessário fazer esta validação pois a concentradora Fusion está mandando abastecimentos duplicados
			MID->(DbOrderNickName("MID_001")) //MID_FILIAL+MID_XCONCE+MID_LADBOM+MID_NLOGIC+DTOS(MID_DATACO)+MID_HORACO+STR(MID_LITABA)
			if MID->(DbSeek(xFilial("MID") + cConcent + cLado + cNLogic + DTOS(dDataAbast) + cHoraAbast + STR(nQtdAbast)))

				cMsg := " Atenção - Abastecimento já cadastrado: lado bomba + número lógico bico + data + hora + quantidade!"

				Help(,,'Help',,cMsg,1,0)
				lRet := .F.

			endif

		endif

	ElseIf cIdPonto == 'MODELCOMMITNTTS' // após gravação

		if oObj:GetOperation() == 3 // inclusão

			// envio o abastecimento cadastrado para a tabela de saída MD6, para ser levado para Retaguarda
			//Danilo: passado ultimo parametro .F. para nao gerar SLI. 
			//Alinhado com Anderson, que tabela MID não necessita gerar SLI quando inclusao ou alteração
			U_UReplica("MID",1,xFilial("MID") + oModelMID:GetValue( 'MID_CODABA' ),"I", .F.)

			// verifico se existe diverência de encerrantes
			ValidaEncerrante(oModelMID:GetValue('MID_CODBIC'),oModelMID:GetValue('MID_CODABA'))

		endif

	Endif

	RestArea(aAreaMID)
	RestArea(aArea)

Return(lRet)


/*/{Protheus.doc} ValidaEncerrante
Função que faz a gravação dos encerrantes
@type function
@param Caractere - cBico - Codigo do Bico
@param Caractere - cAbastecimento - Codigo do Abastecimento
@author Totvs TBC
@since 19/05/2014
@version 1.0
/*/
Static Function ValidaEncerrante(cBico,cAbastecimento)

	Local aArea			:= GetArea()
	Local aAreaMID		:= MID->(GetArea())
	Local nEnceAnt		:= 0
	Local nEnceAtu		:= 0
	Local nQtdAtu		:= 0
	Local nDivergencia	:= 0
	Local nCasaMilhao	:= 0
	Local nLimiteDiv	:= SuperGetMv("MV_XDIVERG",,5) //-- Limite de divergencia para gerar abastecimento automatico de divergencia
	Local lGrvDivMenor	:= SuperGetMv("MV_XVLDDIV",,.F.) //-- Grava falg de abastecimento de divergencia
	Local lHasEncerr := .F.

	Local cErroLOG := "\AUTOCOM\CONCENTRADORA"
	Local cNomeArq := ""
	Local cTexto   := ""

	//Conout(" >> VALIDACAO DE ENCERRANTES ")

	// posiciono no abastecimento atual
	MID->(DbSetOrder(1)) //MID_FILIAL+MID_CODABA
	if MID->(DbSeek(xFilial("MID") + cAbastecimento))

		if MID->MID_XDIVER == "1" // se o abastecimento atual não for de divergência

			// nao executo validacao de divergencia para divisao ou agrupamento de abastecimento
			if !IsInCallStack("U_TPDVA09B") .AND. !IsInCallStack("U_TPDVA09C")//Função para baixa trocada de abastecimentos - "dividir" ou "aglutinar" abastecimento

				nEnceAtu 	:= MID->MID_ENCFIN // armazeno o encerrante atual
				nQtdAtu		:= MID->MID_LITABA  // armazeno a quantidade atual

				// Alterado por Wellington Gonçalves dia 05/04/2017
				// Para encontrar o último encerrante deste bico, será levado em consideração as manutenções de bomba já realizadas
				// Chamo função que retorna o último encerrante do bico
				nEnceAnt := U_RetUltEncer(,,@lHasEncerr,nEnceAtu)

				//Conout("")
				//Conout("")
				//Conout(">> ENCERRANTE FINAL ATUAL ->> nEnceAtu = " + U_XtoStrin(nEnceAtu))
				//Conout(">> ENCERRANTE FINAL ANTERIOR ->> nEnceAnt = " + U_XtoStrin(nEnceAnt))
				//Conout(">> QTD ABASTECIMENTO ATUAL ->> nQtdAtu = " + U_XtoStrin(nQtdAtu))
				//Conout(">> DIVERGENCIA ->> nDivergencia = " + U_XtoStrin(nEnceAtu - (nEnceAnt + nQtdAtu)))
				//Conout("")
				//Conout("")

				// verifico se existe divergência de encerrante
				if nEnceAnt + nQtdAtu <> nEnceAtu

					// Data: 23/03/2018 -- casa do milhão
					nCasaMilhao := int(((nEnceAnt + nQtdAtu) - nEnceAtu) / 1000000)

					// -- Tratamento da casa do milhao (+1000000)
					if ((nEnceAnt + nQtdAtu) - (nEnceAtu + 1000000)) >= -1 .and. ((nEnceAnt + nQtdAtu) - (nEnceAtu + 1000000)) <= 1 // considera intervalo de 1 litro a mais ou a menos (tolerancia)

						//-- ajusto o encerrante
						U_AltAbMID(MID->MID_CODABA, {;
							{"MID_ENCFIN",(nEnceAtu + 1000000)},;
							{"MID_ENCINI",((nEnceAtu + 1000000) - nQtdAtu)};
						})

						//-- ajusto o bico para considerar a nova casa do milhão
						MIC->(DbSetOrder(2)) //MIC_FILIAL+MIC_CODBOM+MIC_CODBIC
						if MIC->(DbSeek(xFilial("MIC") + MID->MID_CODBOM + MID->MID_CODBIC ))
							While MIC->(!Eof()) .AND. MIC->MIC_FILIAL+MIC->MIC_CODBOM+MIC->MIC_CODBIC == xFilial("MIC") + MID->MID_CODBOM + MID->MID_CODBIC
								if MIC->MIC_XCONCE == MID->MID_XCONCE .AND. MIC->MIC_CODTAN == MID->MID_CODTAN .AND. MIC->MIC_NLOGIC == MID->MID_NLOGIC .AND. MIC->MIC_LADO == MID->MID_LADBOM ;
									.AND. ((MIC->MIC_STATUS = '1' .AND. MIC->MIC_XDTATI <= MID->MID_DATACO) .OR. (MIC->MIC_STATUS = '2' .AND. MIC->MIC_XDTDES >= MID->MID_DATACO))

									//-- gera log, para monitoramento
									cTexto := " " + CRLF ;
										+ ">> AJUSTE DA CASA DO MILHAO (+1000000) << " + CRLF ;
										+ " " + CRLF ;
										+ "DATA: "+DtoC(Date()) + CRLF ;
										+ "HORA: "+Time() + CRLF ;
										+ " " + CRLF ;
										+ "CONCENTRADORA: "+MIC->MIC_XCONCE + CRLF ;
										+ "NUM. BICO: "+MIC->MIC_CODBIC + CRLF ;
										+ "NUM. LOGICO: "+MIC->MIC_NLOGIC + CRLF ;
										+ "PRODUTO: "+AllTrim(MID->MID_XPROD)+" - "+Alltrim(Posicione("SB1",1,xFilial("SB1")+MID->MID_XPROD,"B1_DESC")) + CRLF ;
										+ "COD. ABASTECIMENTO: "+MID->MID_CODABA + CRLF ;
										+ " " + CRLF ;
										+ "ENCERRANTE ATUAL: "+cValToChar(nEnceAtu) + CRLF ;
										+ "ENCERRANTE AJUSTADO: "+cValToChar(nEnceAtu + 1000000) + CRLF ;
										+ " " + CRLF ;
										+ "CASA DO MILHAO ATUAL: "+cValToChar(MIC->MIC_XMILHA) + CRLF ;
										+ "CASA DO MILHAO AJUSTADA: "+cValToChar(MIC->MIC_XMILHA + 1) + CRLF ;
										+ " " + CRLF ;
										+ " " + CRLF

									cNomeArq := "LOG_TRETM008_"+DtoS(dDataBase)+"_"+SUBSTR(Time(),1,2)+SUBSTR(Time(),4,2)+SUBSTR(Time(),7,2)+".log"
									U_UCriaLog(cErroLOG+"\",cNomeArq,cTexto)

									//-- atualiza a casa do milhao do cadastro de bico
									RecLock("MIC",.F.)
									MIC->MIC_XMILHA := MIC->MIC_XMILHA + 1
									MIC->(MsUnlock())
									U_UReplica("MIC",2,MIC->MIC_FILIAL+MIC->MIC_CODBOM+MIC->MIC_CODBIC,"A")

									Exit
								endif
								MIC->(DbSkip())
							enddo
						endif

						// -- Tratamento da casa do milhao (-1000000)
						// Obs.: essa tratativa para "voltar" a casa do milhão foi desenvolvida devido a caracteristica da FUSION
						/*

						Ex.:
						volume		initial_volume		final_volume
						151,550		999890,260			1000041,820
						150,000		1000041,820			191,820      -> (MOMENTO EM QUE OCORREU VIRADA, A FUSION ENVIA O ENCERRANTE FINAL SEM A CASA DO MILHAO)
						495,010		191,820				1000686,830  -> (APOS VIRADA, A FUSION VOLTA A ENVIAR A CASA DO MILHAO)
						*/
					elseif ((nEnceAnt + nQtdAtu) - (nEnceAtu - 1000000)) >= -1 .and. ((nEnceAnt + nQtdAtu) - (nEnceAtu - 1000000)) <= 1 // considera intervalo de 1 litro a mais ou a menos (tolerancia)

						//-- ajusto o encerrante
						U_AltAbMID(MID->MID_CODABA, {;
							{"MID_ENCFIN",(nEnceAtu - 1000000)},;
							{"MID_ENCINI",((nEnceAtu - 1000000) - nQtdAtu)};
						})

						//-- ajusto o bico para considerar a nova casa do milhão
						MIC->(DbSetOrder(2)) //MIC_FILIAL+MIC_CODBOM+MIC_CODBIC
						if MIC->(DbSeek(xFilial("MIC") + MID->MID_CODBOM + MID->MID_CODBIC ))
							While MIC->(!Eof()) .AND. MIC->MIC_FILIAL+MIC->MIC_CODBOM+MIC->MIC_CODBIC == xFilial("MIC") + MID->MID_CODBOM + MID->MID_CODBIC
								if MIC->MIC_XCONCE == MID->MID_XCONCE .AND. MIC->MIC_CODTAN == MID->MID_CODTAN .AND. MIC->MIC_NLOGIC == MID->MID_NLOGIC .AND. MIC->MIC_LADO == MID->MID_LADBOM ;
									.AND. ((MIC->MIC_STATUS = '1' .AND. MIC->MIC_XDTATI <= MID->MID_DATACO) .OR. (MIC->MIC_STATUS = '2' .AND. MIC->MIC_XDTDES >= MID->MID_DATACO))

									//-- gera log, para monitoramento
									cTexto := " " + CRLF ;
									+ ">> AJUSTE DA CASA DO MILHAO (-1000000) << " + CRLF ;
									+ " " + CRLF ;
									+ "DATA: "+DtoC(Date())+"" + CRLF ;
									+ "HORA: "+Time()+"" + CRLF ;
									+ " " + CRLF ;
									+ "CONCENTRADORA: "+MIC->MIC_XCONCE+"" + CRLF ;
									+ "NUM. BICO: "+MIC->MIC_CODBIC+"" + CRLF ;
									+ "NUM. LOGICO: "+MIC->MIC_NLOGIC+"" + CRLF ;
									+ "PRODUTO: "+AllTrim(MID->MID_XPROD)+" - "+Alltrim(Posicione("SB1",1,xFilial("SB1")+MID->MID_XPROD,"B1_DESC")) + CRLF ;
									+ "COD. ABASTECIMENTO: "+MID->MID_CODABA + CRLF ;
									+ " " + CRLF ;
									+ "ENCERRANTE ATUAL: "+cValToChar(nEnceAtu)+"" + CRLF ;
									+ "ENCERRANTE AJUSTADO: "+cValToChar(nEnceAtu - 1000000)+"" + CRLF ;
									+ " " + CRLF ;
									+ "CASA DO MILHAO ATUAL: "+cValToChar(MIC->MIC_XMILHA) + CRLF ;
									+ "CASA DO MILHAO AJUSTADA: "+cValToChar(MIC->MIC_XMILHA - 1) + CRLF ;
									+ " " + CRLF ;
									+ " " + CRLF

									cNomeArq := "LOG_TRETM008_"+DtoS(dDataBase)+"_"+SUBSTR(Time(),1,2)+SUBSTR(Time(),4,2)+SUBSTR(Time(),7,2)+".log"
									U_UCriaLog(cErroLOG+"\"/*cPasta*/,cNomeArq/*cNomeArq*/,cTexto/*cTexto*/)

									//-- atualiza a casa do milhao do cadastro de bico
									RecLock("MIC",.F.)
									MIC->MIC_XMILHA := MIC->MIC_XMILHA - 1
									MIC->(MsUnlock())
									U_UReplica("MIC",2,MIC->MIC_FILIAL+MIC->MIC_CODBOM+MIC->MIC_CODBIC,"A")

									Exit
								endif
								MIC->(DbSkip())
							enddo
						endif

						//-- Tratamento para a fusion BUGADA
					elseif nCasaMilhao>0 .and. (int(nEnceAnt + nQtdAtu) == int(nEnceAtu + (nCasaMilhao * 1000000)))

						//-- ajusto o encerrante
						U_AltAbMID(MID->MID_CODABA, {;
							{"MID_ENCFIN",((nCasaMilhao * 1000000) + nEnceAtu)},;
							{"MID_ENCINI",(((nCasaMilhao * 1000000) + nEnceAtu) - nQtdAtu)};
						})

						//-- ajusto o bico para considerar a nova casa do milhão
						MIC->(DbSetOrder(2)) //MIC_FILIAL+MIC_CODBOM+MIC_CODBIC
						if MIC->(DbSeek(xFilial("MIC") + MID->MID_CODBOM + MID->MID_CODBIC ))
							While MIC->(!Eof()) .AND. MIC->MIC_FILIAL+MIC->MIC_CODBOM+MIC->MIC_CODBIC == xFilial("MIC") + MID->MID_CODBOM + MID->MID_CODBIC
								if MIC->MIC_XCONCE == MID->MID_XCONCE .AND. MIC->MIC_CODTAN == MID->MID_CODTAN .AND. MIC->MIC_NLOGIC == MID->MID_NLOGIC .AND. MIC->MIC_LADO == MID->MID_LADBOM ;
									.AND. ((MIC->MIC_STATUS = '1' .AND. MIC->MIC_XDTATI <= MID->MID_DATACO) .OR. (MIC->MIC_STATUS = '2' .AND. MIC->MIC_XDTDES >= MID->MID_DATACO))

									//-- gera log, para monitoramento
									cTexto := " " + CRLF ;
									+ ">> AJUSTE DA CASA DO MILHAO (SOMENTE ENCERRANTE) << " + CRLF ;
									+ " " + CRLF ;
									+ "DATA: "+DtoC(Date())+"" + CRLF ;
									+ "HORA: "+Time()+"" + CRLF ;
									+ " " + CRLF ;
									+ "CONCENTRADORA: "+MIC->MIC_XCONCE+"" + CRLF ;
									+ "NUM. BICO: "+MIC->MIC_CODBIC+"" + CRLF ;
									+ "NUM. LOGICO: "+MIC->MIC_NLOGIC+"" + CRLF ;
									+ "PRODUTO: "+AllTrim(MID->MID_XPROD)+" - "+Alltrim(Posicione("SB1",1,xFilial("SB1")+MID->MID_XPROD,"B1_DESC")) + CRLF ;
									+ "COD. ABASTECIMENTO: "+MID->MID_CODABA + CRLF ;
									+ " " + CRLF ;
									+ "ENCERRANTE ATUAL: "+cValToChar(nEnceAtu)+"" + CRLF ;
									+ "ENCERRANTE AJUSTADO: "+cValToChar(nEnceAtu + (nCasaMilhao*1000000))+"" + CRLF ;
									+ " " + CRLF ;
									+ "NAO ATUALIZA A CASA DO MILHAO DO CADASTRO DE BICO" + CRLF ;
									+ " " + CRLF ;
									+ " " + CRLF

									cNomeArq := "LOG_TRETM008_"+DtoS(dDataBase)+"_"+SUBSTR(Time(),1,2)+SUBSTR(Time(),4,2)+SUBSTR(Time(),7,2)+".log"
									U_UCriaLog(cErroLOG+"\"/*cPasta*/,cNomeArq/*cNomeArq*/,cTexto/*cTexto*/)

									//-- NÃO atualiza a casa do milhao do cadastro de bico

									Exit
								endif
								MIC->(DbSkip())
							enddo
						endif

						//-- Calcula a diferença de encerrante
					else
						nDivergencia := nEnceAtu - (nEnceAnt + nQtdAtu)
					endif
				endif


				// se a divergência for para menos
				if nDivergencia < 0 .AND. ( -1 * nDivergencia ) > nLimiteDiv

					//Conout(" >> DIVERGENCIA PARA MENOS ENCONTRADA NO ABASTECIMENTO " + cAbastecimento)
					//Conout(" >> nDivergencia = " + U_XtoStrin(nDivergencia))

					// se o encerrante atual for diferente do anterior,  e não foi gravado o encerrante anteriormente
					if nEnceAnt <> nEnceAtu .AND. !lHasEncerr

						// altera o abastecimento
						if lGrvDivMenor
							U_AltAbMID(MID->MID_CODABA,{{"MID_XDIVER","3"}})
						else
							//Conout(" PARAMETRO 'MV_XVLDDIV' DESABILITADO. NAO SERA GRAVADO O CAMPO DE DIVERGENCIA.")
						endif

					else

						// exclui abastecimento
						//Conout(" >> DIVERGENCIA ABASTECIMENTO DUPLICADO, ENCERRANTE JA CADASTRADO. COD ABAST: " + cAbastecimento)
						U_ExcAbMID(MID->MID_CODABA)

					endif

				elseif nDivergencia > 0 .AND. nDivergencia > nLimiteDiv // se a divergência for para mais

					//Conout(" >> DIVERGENCIA PARA MAIS ENCONTRADA NO ABASTECIMENTO " + cAbastecimento)

					// foi solicitado pela marajo que quando uma divergencia for superior a cem mil
					// não seja cadastrado um abastecimento de divergencia, significa que a fusion emulando a CBC
					// enviou o primeiro abastecimento sem o número do milhão
					if nDivergencia < 100000

						// gravo um novo abastecimento com a quantidade de litros da divergencia
						aCampos := {}
						aAdd( aCampos, { 'MID_FILIAL'	, xFilial("MID")	 				} )
						aAdd( aCampos, { 'MID_DATACO' 	, MID->MID_DATACO	  				} )
						aAdd( aCampos, { 'MID_HORACO' 	, MID->MID_HORACO	  				} )
						aAdd( aCampos, { 'MID_XPROD' 	, MID->MID_XPROD					} )
						aAdd( aCampos, { 'MID_XCONCE' 	, MID->MID_XCONCE    				} )
						aAdd( aCampos, { 'MID_CODBOM' 	, MID->MID_CODBOM    				} )
						aAdd( aCampos, { 'MID_CODTAN' 	, MID->MID_CODTAN 					} )
						aAdd( aCampos, { 'MID_CODBIC' 	, MID->MID_CODBIC 					} )
						aAdd( aCampos, { 'MID_NLOGIC' 	, MID->MID_NLOGIC  					} )
						aAdd( aCampos, { 'MID_LADBOM' 	, MID->MID_LADBOM  					} )
						aAdd( aCampos, { 'MID_LITABA' 	, nDivergencia    					} )
						aAdd( aCampos, { 'MID_PREPLI' 	, MID->MID_PREPLI  					} )
						aAdd( aCampos, { 'MID_TOTAPA' 	, nDivergencia * MID->MID_PREPLI	} )
						aAdd( aCampos, { 'MID_ENCINI'   , nEnceAnt							} ) //Encerrante inicial
						aAdd( aCampos, { 'MID_ENCFIN' 	, (nEnceAnt + nDivergencia)			} )
						aAdd( aCampos, { 'MID_RFID' 	, MID->MID_RFID 					} )
						aAdd( aCampos, { 'MID_DTBASE' 	, MID->MID_DTBASE 					} )
						aAdd( aCampos, { 'MID_LEITUR' 	, MID->MID_LEITUR  					} )
						aAdd( aCampos, { 'MID_XDIVER' 	, "2"  			  					} )
						aAdd( aCampos, { 'MID_NUMORC' 	, "P" 								} ) //Abastecimento Pendente
						aAdd( aCampos, { 'MID_CODANP'	, MID->MID_CODANP 					} ) 
						aAdd( aCampos, { 'MID_PBIO'		, MID->MID_PBIO } ) 
						aAdd( aCampos, { 'MID_UFORIG'	, MID->MID_UFORIG } ) 
						aAdd( aCampos, { 'MID_PORIG'	, MID->MID_PORIG } ) 
						aAdd( aCampos, { 'MID_INDIMP'	, MID->MID_INDIMP } ) 
						aAdd( aCampos, { 'MID_ENVSPE' 	, "S" 								} ) //Envia SPED: S-Sim;N-Nao

						// faço a gravação do abastecimento
						U_GrvAbMID(aCampos)

					else
						//Conout(" >> DIVERGENCIA PARA MAIS MAIOR QUE 100000 - DESCONSIDERADA ")
					endif

				endif

			endif

		endif

	endif

	RestArea(aArea)
	RestArea(aAreaMID)

Return()

/*/{Protheus.doc} RetUltEncer
Função que retorna o último encerrante do bico

@type function
@param Caractere - nEnceAnt - Numero do Encerrante anterior
@author Wellington Gonçalves
@since 19/05/2014
@version 1.0
/*/
User Function RetUltEncer(cCodBico, cCodAbast, lHasEncerr, nEnceAtu)

	Local nRecnoAtu		:= MID->(Recno()) // armazeno o recno do abastecimento atual
	Local cCondicao	 	:= ""
	Local bCondicao		:= NIL
	Local dDtManut		:= CTOD("  /  /    ")
	Local cHrManut		:= "  "
	Local cMnManut		:= "  "
	Local nEncManut		:= 0
	Local nEnceAnt		:= 0
	Local nX

	Default cCodBico := MID->MID_CODBIC
	Default cCodAbast := MID->MID_CODABA
	Default lHasEncerr := Nil
	Default nEnceAtu := 0

	//Conout(">> TRETM008 - RetUltEncer ->> INICIO - DATA: " + DTOC(Date()) + " - HORA: " + TIME())

	// função que retorna a última manutenção da bomba
	//RetManutBomba(@dDtManut,@cHrManut,@cMnManut,@nEncManut,MID->MID_CODBOM,cCodBico,MID->MID_DATACO,MID->MID_HORACO)

	cCondicao 	:= " MID->MID_FILIAL = '" + xFilial("MID") + "' "
	cCondicao 	+= " .AND. MID->MID_CODBIC == '" + cCodBico + "' "
	cCondicao 	+= " .AND. MID->MID_CODABA <> '" + cCodAbast + "' "

	// se já foi realizada uma manutenção na bomba
	if !Empty(dDtManut)
		cCondicao 	+= " .AND. DTOS(MID->MID_DATACO) >= '" + DTOS(dDtManut) + "' "
		//cCondicao 	+= " .AND. ( SubStr(MID->MID_HORACO,1,2) + SubStr(MID->MID_HORACO,4,2) ) >= '" + cHrManut + cMnManut + "' "
	endif

	MID->(DbOrderNickName("MID_002")) //MID_FILIAL+MID_CODBIC+STR(MID_ENCFIN)+MID_CODABA

	// limpo os filtros da MID
	MID->(DbClearFilter())

	// faço um filtro na MID
	bCondicao 	:= "{|| " + cCondicao + " }"
	MID->(DbSetFilter(&bCondicao,cCondicao))

	// posiciono no último abastecimento deste bico
	MID->(DbGoBottom())

	// se já existir abastecimento para este bico
	if MID->(!Eof()) .And. DTOS(MID->MID_DATACO)+SubStr(MID->MID_HORACO,1,2)+SubStr(MID->MID_HORACO,4,2) >= ;
		DTOS(dDtManut)+cHrManut+cMnManut
		
		nEnceAnt := MID->MID_ENCFIN
		
		//verifico se ja existe encerrante, nos X abastecimentos anteriores
		if lHasEncerr <> Nil
			For nX:=1 to 5
				if MID->MID_ENCFIN == nEnceAtu
					lHasEncerr := .T.
					EXIT
				endif
				MID->(DbSkip(-1))
				if MID->(!Bof())
					EXIT
				endif
			next nX
			//Conout(">> TRETM008 - RetUltEncer ->> lHasEncerr = " + iif(lHasEncerr,".T.",".F."))
		endif
		
	else

		// se já teve uma manutenção de bomba
		if !Empty(dDtManut)
			// considero o encerrante da manutenção da bomba
			nEnceAnt := nEncManut
		else
			// encerrante zerado, primeiro abastecimento
			nEnceAnt := 0
		endif

	endif

	// limpo os filtros da MID
	MID->(DbClearFilter())

	// volto para o abastecimento atual
	MID->(DbGoTo(nRecnoAtu))

	//Conout(">> TRETM008 - RetUltEncer ->> nEnceAnt = " + U_XtoStrin(nEnceAnt))
	//Conout(">> TRETM008 - RetUltEncer ->> FIM - DATA: " + DTOC(Date()) + " - HORA: " + TIME())

Return nEnceAnt
